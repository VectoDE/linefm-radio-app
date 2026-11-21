import 'dart:async';

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

  /// Schliesst WebSocket und Timer.
  void dispose();
}

/// Statische Daten ohne Netzwerk.
class FakeNowPlayingRepository implements NowPlayingRepository {
  FakeNowPlayingRepository({
    Map<String, Track> tracks = const <String, Track>{},
    this.history = const <HistoryEntry>[],
    this.listeners,
    // ignore: prefer_initializing_formals
  }) : _tracks = tracks;

  final Map<String, Track> _tracks;
  final List<HistoryEntry> history;
  final int? listeners;

  @override
  Stream<List<StationLive>> watchStations() =>
      Stream<List<StationLive>>.value(<StationLive>[
        for (final s in stationsCatalog)
          StationLive(station: s, track: _tracks[s.slug]),
      ]);

  @override
  Stream<Track?> watchTrack(Station station) =>
      Stream<Track?>.value(_tracks[station.slug]);

  @override
  Stream<List<HistoryEntry>> watchHistory(Station station) =>
      Stream<List<HistoryEntry>>.value(history);

  @override
  Stream<int?> watchListeners(Station station) => Stream<int?>.value(listeners);

  @override
  Stream<bool> watchOnline() => Stream<bool>.value(true);

  @override
  void setActiveStation(Station station) {}

  @override
  void setForeground({required bool value}) {}

  @override
  void setPlaying({required bool value}) {}

  @override
  Future<void> refresh() async {}

  @override
  void dispose() {}
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
  }) : _fixedStations = stations,
       _active = activeStation ?? (stations ?? stationsCatalog).first;

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
  /// Feste Liste (Tests); sonst die aktuelle Senderliste (Issue #91).
  final List<Station>? _fixedStations;

  List<Station> get _stations => _fixedStations ?? stationsCatalog;

  Station _active;
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

  /// Die Senderliste hat sich geaendert (Issue #91): Liste neu melden und
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
      if (live != null) HistoryEntry(track: live, isLive: true),
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

  // --------------------------------------------------------------- Abruf

  Future<void> _pollOnce({bool force = false, bool bypassGap = false}) async {
    if (_disposed) return;
    if (!_awake && !force) return;
    final jobs = <Future<void>>[
      _fetchActive(includeHistory: _foreground, bypassGap: bypassGap),
    ];
    // Auch bei verbundenem WebSocket: verpasste Nachrichten (z. B. vor dem
    // Verbinden) werden so spaetestens nach einem Intervall korrigiert.
    if (_foreground) {
      for (final s in _stations) {
        if (s != _active) {
          jobs.add(_fetchCurrent(s.slug, bypassGap: bypassGap));
        }
      }
    }
    await Future.wait(jobs);
  }

  Future<void> _fetchActive({
    required bool includeHistory,
    bool bypassGap = false,
  }) async {
    final slug = _active.slug;
    await Future.wait(<Future<void>>[
      _fetchCurrent(slug, bypassGap: bypassGap),
      if (includeHistory) _fetchHistory(slug, bypassGap: bypassGap),
      if (includeHistory) _fetchListeners(slug, bypassGap: bypassGap),
    ]);
    _scheduleEndsAt();
  }

  Future<void> _fetchCurrent(String slug, {bool bypassGap = false}) async {
    final track = await _guard(
      'current:$slug',
      () => _api.currentSong(slug),
      bypassGap: bypassGap,
    );
    if (track == null || _disposed) return;
    _applyTrack(slug, track.value);
  }

  Future<void> _fetchHistory(String slug, {bool bypassGap = false}) async {
    final list = await _guard(
      'last:$slug',
      () => _api.lastSongs(slug),
      bypassGap: bypassGap,
    );
    if (list == null || _disposed) return;
    _last[slug] = list.value;
    _emit();
  }

  Future<void> _fetchListeners(String slug, {bool bypassGap = false}) async {
    final n = await _guard(
      'listeners:$slug',
      () => _api.listeners(slug),
      bypassGap: bypassGap,
    );
    if (n == null || _disposed) return;
    if (_listeners[slug] == n.value) return;
    _listeners[slug] = n.value;
    _emit();
  }

  /// `null` bei Fehler oder wenn der Abruf zusammengefasst wurde (gleiche
  /// Adresse zuletzt vor weniger als [minRefetchGap]); sonst das Ergebnis in
  /// einer Huelle (auch fuer `null`-Werte der API). Ein laufender Abruf
  /// derselben Adresse wird mitbenutzt.
  Future<_Box<T>?> _guard<T>(
    String key,
    Future<T> Function() call, {
    bool bypassGap = false,
  }) {
    final running = _inFlight[key];
    if (running != null) return running.then((v) => v as _Box<T>?);
    final last = _fetchedAt[key];
    if (!bypassGap &&
        last != null &&
        _clock.now().difference(last) < minRefetchGap) {
      return Future<_Box<T>?>.value();
    }
    final future = _request(call).whenComplete(() {
      _inFlight.remove(key);
      _fetchedAt[key] = _clock.now();
    });
    _inFlight[key] = future;
    return future;
  }

  Future<_Box<T>?> _request<T>(Future<T> Function() call) async {
    try {
      final value = await call();
      _setOnline(true);
      return _Box<T>(value);
    } on LautApiException catch (e) {
      logError('laut.fm', e);
      _setOnline(true);
      return null;
    } on Object catch (e) {
      logError('laut.fm nicht erreichbar', e);
      _setOnline(false);
      return null;
    }
  }

  void _setOnline(bool value) {
    if (_online == value || _disposed) return;
    _online = value;
    _emit();
  }

  // -------------------------------------------------------------- Titel

  void _onSongChange(SongChange change) {
    if (_disposed) return;
    final startedAt = change.track.startedAt;
    final now = _clock.now();
    if (startedAt != null && startedAt.isAfter(now)) {
      final wait = startedAt.difference(now);
      if (wait <= maxAnnounceDelay) {
        _announced.remove(change.stationSlug)?.cancel();
        _announced[change.stationSlug] = timer(wait, () {
          _announced.remove(change.stationSlug);
          _applyTrack(change.stationSlug, change.track);
          if (change.stationSlug == _active.slug) _scheduleEndsAt();
        });
        return;
      }
    }
    _applyTrack(change.stationSlug, change.track);
    if (change.stationSlug == _active.slug) _scheduleEndsAt();
  }

  void _applyTrack(String slug, Track? track) {
    if (_disposed) return;
    final old = _current[slug];
    if (track == null) {
      if (old == null && _current.containsKey(slug)) return;
      _current[slug] = null;
      _emit();
      return;
    }
    if (old != null && _sameSong(old, track)) {
      // Gleicher Song: nur fehlende Details nachtragen (z. B. korrigiertes
      // Ende), Cover behalten.
      if (old.endsAt != track.endsAt && track.endsAt != null) {
        _current[slug] = old.copyWith(endsAt: track.endsAt);
        _emit();
      }
      return;
    }
    // Startet der "neue" Titel vor dem bekannten, ist es eine veraltete
    // Antwort (Cache); ignorieren.
    final oldStart = old?.startedAt;
    final newStart = track.startedAt;
    if (oldStart != null && newStart != null && newStart.isBefore(oldStart)) {
      return;
    }
    _current[slug] = track;
    if (old != null) {
      final last = _last[slug] ?? const <Track>[];
      if (last.isEmpty || !_sameSong(last.first, old)) {
        _last[slug] = <Track>[old, ...last].take(10).toList();
      }
    }
    _emit();
    if (slug == _active.slug) unawaited(_lookupCover(slug, track));
  }

  Future<void> _lookupCover(String slug, Track track) async {
    if (track.artworkUrl != null) return;
    final result = await _artwork.lookup(track, priority: true);
    final url = result?.artworkUrl;
    if (url == null || _disposed) return;
    final current = _current[slug];
    if (current == null || !_sameSong(current, track)) return;
    _current[slug] = current.copyWith(artworkUrl: url);
    _emit();
  }

  void _scheduleEndsAt() {
    _endsAtTimer?.cancel();
    _endsAtTimer = null;
    if (_disposed || !_awake) return;
    final endsAt = _current[_active.slug]?.endsAt;
    Duration delay;
    if (endsAt == null) {
      delay = unknownEndDelay;
    } else {
      delay = endsAt.add(endsAtLead).difference(_clock.now());
      if (delay < minEndsAtDelay) delay = minEndsAtDelay;
      if (delay > maxEndsAtDelay) delay = maxEndsAtDelay;
    }
    lastEndsAtDelay = delay;
    _endsAtTimer = timer(delay, () {
      _endsAtTimer = null;
      unawaited(_fetchActive(includeHistory: _foreground));
    });
  }

  void _emit() {
    if (!_changed.isClosed) _changed.add(null);
  }

  static bool _sameSong(Track a, Track b) {
    if (a.artist.toLowerCase() != b.artist.toLowerCase() ||
        a.title.toLowerCase() != b.title.toLowerCase()) {
      return false;
    }
    final sa = a.startedAt;
    final sb = b.startedAt;
    return sa == null || sb == null || sa.isAtSameMomentAs(sb);
  }
}

class _Box<T> {
  const _Box(this.value);
  final T value;
}
