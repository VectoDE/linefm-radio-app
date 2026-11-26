import 'dart:async';
import 'dart:convert';

import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/data/api/song_change_socket.dart';
import 'package:linefm_radio/data/artwork/itunes_artwork.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/now_playing.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';

part 'now_playing_fetch.dart';
part 'now_playing_snapshot.dart';

/// Live-Daten-Motor: vereint WebSocket, ends_at-Timer und Polling
/// (Spec 3.3).
abstract interface class NowPlayingRepository {
  Stream<List<StationLive>> watchStations();

  /// Aktueller Titel; bei der aktiven Station inklusive Cover-URL, sobald
  /// der Lookup fertig ist.
  Stream<Track?> watchTrack(Station station);

  /// LIVE-Eintrag (aktueller Titel) plus bis zu 10 letzte Songs, Duplikat
  /// zum Live-Titel entfernt.
  Stream<List<HistoryEntry>> watchHistory(Station station);

  Stream<int?> watchListeners(Station station);

  /// `false`, solange laut.fm nicht erreichbar ist (Offline-Leiste).
  Stream<bool> watchOnline();

  /// Gewaehlte Station (ends_at-Timer, Verlauf, Hoererzahl, Cover).
  void setActiveStation(Station station);

  /// App im Vordergrund sichtbar (AppLifecycleState.resumed).
  void setForeground({required bool value});

  /// Wiedergabe laeuft (auch im Hintergrund).
  void setPlaying({required bool value});

  Future<void> refresh();

  /// Forgets the tracks and history restored from the device ("clear
  /// storage"); the UI falls back to the station logo and an empty history
  /// until live data arrives.
  void forgetRestored();

  /// Schliesst WebSocket und Timer.
  void dispose();
}

/// Echte Implementierung.
///
/// 1. WebSocket nur, wenn uebergeben (Standard: keiner, `WS_ENABLED=false`)
///    und vom Traffic-Waechter erlaubt; aktiv
///    solange Vordergrund oder Wiedergabe. Wechsel, die laut.fm vor
///    `started_at` ankuendigt (gemessen ca. 7 s vorher), werden erst zum
///    Startzeitpunkt uebernommen.
/// 2. ends_at-Timer fuer die aktive Station: Abruf bei `ends_at + 3 s`
///    (min. 10 s, max. 10 min). Ohne bekanntes Ende (Live-Sendung)
///    alle [unknownEndDelay].
/// 3. Polling alle [pollInterval]: im Vordergrund `current_song` aller
///    Sender (auch bei verbundenem WebSocket, als Korrektur) sowie
///    `last_songs` und `listeners` der aktiven Station. Im Hintergrund nur
///    die aktive Station und nur bei Wiedergabe.
/// 4. Neuer Titel der aktiven Station -> Cover-Lookup (Prioritaet).
class LiveNowPlayingRepository implements NowPlayingRepository {
  LiveNowPlayingRepository({
    required this._api,
    this._socket,
    this._artwork = const NoopArtworkService(),
    this._clock = const SystemClock(),
    List<Station>? stations,
    Station? activeStation,
    this._foreground = true,
    this._playing = false,
    this.pollInterval = const Duration(seconds: 60),
    this.endsAtLead = const Duration(seconds: 3),
    this.minEndsAtDelay = const Duration(seconds: 10),
    this.maxEndsAtDelay = const Duration(minutes: 10),
    this.unknownEndDelay = const Duration(seconds: 30),
    this.maxAnnounceDelay = const Duration(seconds: 60),
    this.minRefetchGap = const Duration(seconds: 5),
    this.timer = Timer.new,
    this.periodicTimer = Timer.periodic,
    String? Function()? readSnapshot,
    this._writeSnapshot,
  }) : _fixedStations = stations,
       _active = activeStation ?? (stations ?? stationsCatalog).first {
    _restore(readSnapshot?.call());
  }

  /// Most history entries kept on the device, across all stations.
  static const int maxStoredHistory = 50;

  /// Saves the snapshot (last track and history per station) on the device.
  final Future<void> Function(String json)? _writeSnapshot;
  String? _lastSnapshot;

  final Duration pollInterval;
  final Duration endsAtLead;
  final Duration minEndsAtDelay;
  final Duration maxEndsAtDelay;
  final Duration unknownEndDelay;
  final Duration maxAnnounceDelay;

  /// Mindestabstand zwischen zwei Abrufen DERSELBEN Adresse (Sender und
  /// Endpunkt). Kurz hintereinander ausgeloeste Abrufe (Start, Stationswechsel,
  /// Vordergrund-Wechsel, Timer) werden so zu einem zusammengefasst; ein
  /// laufender Abruf wird immer mitbenutzt. Nur "Aktualisieren" (Pull-to-
  /// refresh) umgeht den Abstand.
  final Duration minRefetchGap;

  /// Austauschbar fuer deterministische Tests.
  final Timer Function(Duration, void Function()) timer;
  final Timer Function(Duration, void Function(Timer)) periodicTimer;

  final LautApi _api;
  final SongChangeSocket? _socket;
  final ArtworkService _artwork;
  final Clock _clock;

  /// Feste Liste (Tests); sonst die aktuelle Senderliste.
  final List<Station>? _fixedStations;

  List<Station> get _stations => _fixedStations ?? stationsCatalog;

  Station _active;

  /// Zaehlt Stationswechsel; Antworten, die fuer eine fruehere aktive
  /// Station angefordert wurden, planen keinen Timer mehr.
  int _activeGeneration = 0;
  bool _foreground;
  bool _playing;
  bool _started = false;
  bool _disposed = false;
  bool _online = true;
  bool _socketWanted = false;

  final Map<String, Track?> _current = <String, Track?>{};
  final Map<String, List<Track>> _last = <String, List<Track>>{};
  final Map<String, int?> _listeners = <String, int?>{};
  final Map<String, Timer> _announced = <String, Timer>{};
  final Map<String, Future<Object?>> _inFlight = <String, Future<Object?>>{};
  final Map<String, DateTime> _fetchedAt = <String, DateTime>{};

  final StreamController<void> _changed = StreamController<void>.broadcast(
    sync: true,
  );
  StreamSubscription<SongChange>? _socketSub;
  Timer? _pollTimer;
  Timer? _endsAtTimer;

  /// Zuletzt geplante Wartezeit des ends_at-Timers (Tests/Diagnose).
  Duration? lastEndsAtDelay;

  /// Vordergrund oder Wiedergabe: nur dann laufen Timer und WebSocket.
  bool get _awake => _foreground || _playing;

  // ------------------------------------------------------------- Streams

  Stream<T> _watch<T>(T Function() read) {
    _ensureStarted();
    StreamSubscription<void>? sub;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        sub = _changed.stream.listen((_) {
          if (!controller.isClosed) controller.add(read());
        }, onDone: () => unawaited(controller.close()));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  /// Die Senderliste hat sich geaendert: Liste neu melden und
  /// neue Sender beim naechsten Abruf mitnehmen.
  void stationsChanged() {
    if (_disposed) return;
    _changed.add(null);
    if (_started) unawaited(_pollOnce());
  }

  @override
  Stream<List<StationLive>> watchStations() => _watch(_stationsSnapshot);

  @override
  Stream<Track?> watchTrack(Station station) =>
      _watch(() => _current[station.slug]);

  @override
  Stream<List<HistoryEntry>> watchHistory(Station station) =>
      _watch(() => _historyOf(station.slug));

  @override
  Stream<int?> watchListeners(Station station) =>
      _watch(() => _listeners[station.slug]);

  @override
  Stream<bool> watchOnline() => _watch(() => _online);

  List<StationLive> _stationsSnapshot() => <StationLive>[
    for (final s in _stations) StationLive(station: s, track: _current[s.slug]),
  ];

  List<HistoryEntry> _historyOf(String slug) {
    final live = _current[slug];
    final last = _last[slug] ?? const <Track>[];
    return <HistoryEntry>[
      if (live != null) HistoryEntry(track: live, isLive: !live.lastSeen),
      ...last
          .where((t) => live == null || !_sameSong(t, live))
          .take(10)
          .map((t) => HistoryEntry(track: t)),
    ];
  }

  // ----------------------------------------------------------- Steuerung

  @override
  void setActiveStation(Station station) {
    if (_disposed || station == _active) return;
    _active = station;
    _activeGeneration++;
    // Ein gemerkter Titel, dessen Ende schon vorbei ist, stammt
    // aus einem frueheren Abruf (im Hintergrund werden nur die aktive
    // Station und im Vordergrund alle 60 s abgefragt). Statt ihn bis zur
    // Antwort stehen zu lassen, sofort neutral (Sendername) anzeigen.
    final known = _current[station.slug];
    final endsAt = known?.endsAt;
    if (known != null &&
        !known.lastSeen &&
        endsAt != null &&
        endsAt.add(endsAtLead).isBefore(_clock.now())) {
      _current[station.slug] = null;
    }
    _emit();
    if (!_started) return;
    unawaited(_fetchActive(includeHistory: true));
  }

  @override
  void setForeground({required bool value}) {
    if (_disposed || _foreground == value) return;
    _foreground = value;
    if (_started) _reconfigure(refreshNow: value);
  }

  @override
  void setPlaying({required bool value}) {
    if (_disposed || _playing == value) return;
    _playing = value;
    if (_started) _reconfigure(refreshNow: false);
  }

  @override
  Future<void> refresh() async {
    _ensureStarted();
    await _pollOnce(force: true, bypassGap: true);
  }

  @override
  void forgetRestored() {
    if (_disposed) return;
    var changed = false;
    _current.updateAll((_, t) {
      if (t == null || !t.lastSeen) return t;
      changed = true;
      return null;
    });
    for (final slug in _last.keys.toList()) {
      final kept = _last[slug]!.where((t) => !t.lastSeen).toList();
      if (kept.length != _last[slug]!.length) {
        _last[slug] = kept;
        changed = true;
      }
    }
    if (changed) _emit();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    _endsAtTimer?.cancel();
    for (final t in _announced.values) {
      t.cancel();
    }
    _announced.clear();
    unawaited(_socketSub?.cancel());
    _socketSub = null;
    final socket = _socket;
    if (socket != null) unawaited(socket.close());
    unawaited(_changed.close());
  }

  void _ensureStarted() {
    if (_started || _disposed) return;
    _started = true;
    final socket = _socket;
    if (socket != null) {
      _socketSub = socket.changes.listen(_onSongChange);
    }
    _reconfigure(refreshNow: true);
  }

  void _reconfigure({required bool refreshNow}) {
    if (_disposed) return;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_awake) {
      _pollTimer = periodicTimer(pollInterval, (_) => unawaited(_pollOnce()));
    }

    final wantSocket = _socket != null && _awake;
    if (wantSocket != _socketWanted) {
      _socketWanted = wantSocket;
      final socket = _socket!;
      unawaited(wantSocket ? socket.connect() : socket.close());
    }

    if (refreshNow && _awake) {
      unawaited(_pollOnce(force: true));
    } else {
      _scheduleEndsAt();
    }
  }

  void _emit() {
    if (!_changed.isClosed) _changed.add(null);
    _persist();
  }
}

/// [track] with the cover of the same song from [known], if it has none.
Track _withKnownCover(Track track, List<Track> known) {
  if (track.artworkUrl != null) return track;
  for (final k in known) {
    if (k.artworkUrl != null && _sameSong(k, track)) {
      return track.copyWith(artworkUrl: k.artworkUrl);
    }
  }
  return track;
}

bool _sameSong(Track a, Track b) {
  if (a.artist.toLowerCase() != b.artist.toLowerCase() ||
      a.title.toLowerCase() != b.title.toLowerCase()) {
    return false;
  }
  final sa = a.startedAt;
  final sb = b.startedAt;
  return sa == null || sb == null || sa.isAtSameMomentAs(sb);
}

class _Box<T> {
  const _Box(this.value);
  final T value;
}
