import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/data/api/song_change_socket.dart';
import 'package:linefm_radio/data/artwork/itunes_artwork.dart';
import 'package:linefm_radio/data/live/now_playing_repository.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/now_playing.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';

final _t0 = DateTime.utc(2026, 11, 18, 20);

Track _song(String title, {int startMin = 0, int? lengthSec = 180}) {
  final start = _t0.add(Duration(minutes: startMin));
  return Track(
    artist: 'Artist',
    title: title,
    startedAt: start,
    endsAt: lengthSec == null ? null : start.add(Duration(seconds: lengthSec)),
  );
}

class _FakeApi implements LautApi {
  final Map<String, Track?> current = <String, Track?>{};
  final Map<String, List<Track>> last = <String, List<Track>>{};
  final Map<String, int> listenerCount = <String, int>{};
  final List<String> calls = <String>[];
  bool offline = false;

  Future<T> _call<T>(String name, T value) async {
    calls.add(name);
    if (offline) throw http.ClientException('offline');
    return value;
  }

  @override
  Future<Track?> currentSong(String slug) =>
      _call('current:$slug', current[slug]);

  @override
  Future<List<Track>> lastSongs(String slug) =>
      _call('last:$slug', last[slug] ?? const <Track>[]);

  @override
  Future<int?> listeners(String slug) =>
      _call('listeners:$slug', listenerCount[slug]);

  @override
  Future<String?> streamUrl(String slug) async => null;
}

class _FakeSocket implements SongChangeSocket {
  final StreamController<SongChange> controller =
      StreamController<SongChange>.broadcast(sync: true);
  int connects = 0;
  int closes = 0;

  @override
  Stream<SongChange> get changes => controller.stream;

  @override
  Future<void> connect() async => connects++;

  @override
  Future<void> close() async => closes++;
}

class _FakeArtwork implements ArtworkService {
  final List<String> lookups = <String>[];

  @override
  Future<ArtworkResult?> lookup(Track track, {bool priority = false}) async {
    lookups.add('${track.title}:$priority');
    return ArtworkResult(artworkUrl: 'https://cover/${track.title}.jpg');
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this.due, this.callback, {this.period});

  DateTime due;
  final void Function(Timer) callback;
  final Duration? period;
  bool active = true;
  int ticks = 0;

  @override
  void cancel() => active = false;

  @override
  bool get isActive => active;

  @override
  int get tick => ticks;
}

/// Manuelle Zeitsteuerung: Timer laufen nur bei [advance].
class _Scheduler {
  _Scheduler(this.clock);

  final FakeClock clock;
  final List<_FakeTimer> timers = <_FakeTimer>[];

  Timer one(Duration d, void Function() cb) {
    final t = _FakeTimer(clock.now().add(d), (_) => cb());
    timers.add(t);
    return t;
  }

  Timer periodic(Duration d, void Function(Timer) cb) {
    final t = _FakeTimer(clock.now().add(d), cb, period: d);
    timers.add(t);
    return t;
  }

  int get active => timers.where((t) => t.active).length;

  Future<void> advance(Duration d) async {
    final target = clock.now().add(d);
    while (true) {
      final due = timers.where((t) => t.active && !t.due.isAfter(target));
      if (due.isEmpty) break;
      final next = due.reduce((a, b) => a.due.isBefore(b.due) ? a : b);
      clock.setTo(next.due);
      next.ticks++;
      if (next.period == null) {
        next.active = false;
      } else {
        next.due = next.due.add(next.period!);
      }
      next.callback(next);
      await _settle();
    }
    clock.setTo(target);
    await _settle();
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  final main = stationsCatalog.first; // linefm
  final rap = stationsCatalog[1];

  late _FakeApi api;
  late _FakeSocket socket;
  late _FakeArtwork artwork;
  late FakeClock clock;
  late _Scheduler sched;

  setUp(() {
    api = _FakeApi();
    socket = _FakeSocket();
    artwork = _FakeArtwork();
    clock = FakeClock(_t0.add(const Duration(seconds: 30)));
    sched = _Scheduler(clock);
    for (final s in stationsCatalog) {
      api.current[s.slug] = _song('${s.slug}-1');
    }
    api.last['linefm'] = <Track>[
      _song('linefm-1'),
      for (var i = 1; i <= 10; i++) _song('alt$i', startMin: -3 * i),
    ];
    api.listenerCount['linefm'] = 7;
  });

  LiveNowPlayingRepository repo({bool foreground = true}) =>
      LiveNowPlayingRepository(
        api: api,
        socket: socket,
        artwork: artwork,
        clock: clock,
        foreground: foreground,
        timer: sched.one,
        periodicTimer: sched.periodic,
      );

  test('Start: alle Sender, Verlauf mit LIVE ohne Duplikat, Hoerer', () async {
    final r = repo();
    List<StationLive>? stations;
    List<HistoryEntry>? history;
    int? listeners;
    Track? track;
    final subs = <StreamSubscription<Object?>>[
      r.watchStations().listen((v) => stations = v),
      r.watchHistory(main).listen((v) => history = v),
      r.watchListeners(main).listen((v) => listeners = v),
      r.watchTrack(main).listen((v) => track = v),
    ];
    await _settle();

    expect(stations!.map((s) => s.track?.title), <String>[
      for (final s in stationsCatalog) '${s.slug}-1',
    ]);
    expect(history!.first.isLive, isTrue);
    expect(history!.first.track.title, 'linefm-1');
    expect(history!.where((h) => h.track.title == 'linefm-1'), hasLength(1));
    expect(history!.skip(1), hasLength(10));
    expect(listeners, 7);
    expect(socket.connects, 1);
    // Cover fuer die aktive Station mit Prioritaet.
    expect(artwork.lookups, contains('linefm-1:true'));
    expect(track!.artworkUrl, 'https://cover/linefm-1.jpg');

    for (final s in subs) {
      await s.cancel();
    }
    r.dispose();
    expect(socket.closes, 1);
  });

  test('ends_at-Timer: Abruf bei ends_at + 3 s, Grenzen 10 s/10 min', () async {
    final r = repo();
    final sub = r.watchTrack(main).listen((_) {});
    await _settle();
    // Song endet bei t0+180 s, jetzt t0+30 s -> 153 s.
    expect(r.lastEndsAtDelay, const Duration(seconds: 153));

    api.current['linefm'] = _song('linefm-2', startMin: 3);
    api.calls.clear();
    await sched.advance(const Duration(seconds: 153));
    expect(api.calls, contains('current:linefm'));

    // Ende in der Vergangenheit -> Minimum 10 s.
    api.current['linefm'] = _song('linefm-3', startMin: 4);
    clock.advance(const Duration(minutes: 10));
    await r.refresh();
    expect(r.lastEndsAtDelay, const Duration(seconds: 10));

    // Live-Sendung ohne Ende -> 30 s.
    api.current['linefm'] = _song('live', startMin: 12, lengthSec: null);
    await r.refresh();
    expect(r.lastEndsAtDelay, const Duration(seconds: 30));

    // Sehr langes Ende -> Maximum 10 min.
    api.current['linefm'] = _song('lang', startMin: 20, lengthSec: 3600);
    clock.advance(const Duration(minutes: 10));
    await r.refresh();
    expect(r.lastEndsAtDelay, const Duration(minutes: 10));

    await sub.cancel();
    r.dispose();
  });

  test('WebSocket-Wechsel: sofort, angekuendigte erst zum Start', () async {
    final r = repo();
    final titles = <String?>[];
    final sub = r.watchTrack(rap).listen((t) => titles.add(t?.title));
    await _settle();
    expect(titles.last, 'linefmrap-1');

    socket.controller.add(
      SongChange(stationSlug: 'linefmrap', track: _song('jetzt')),
    );
    await _settle();
    expect(titles.last, 'jetzt');

    // laut.fm kuendigt Wechsel ca. 7 s vor started_at an.
    final announced = Track(
      artist: 'Artist',
      title: 'gleich',
      startedAt: clock.now().add(const Duration(seconds: 7)),
    );
    socket.controller.add(
      SongChange(stationSlug: 'linefmrap', track: announced),
    );
    await _settle();
    expect(titles.last, 'jetzt');
    await sched.advance(const Duration(seconds: 7));
    expect(titles.last, 'gleich');

    // Veraltete Antwort (frueherer Start) wird ignoriert.
    socket.controller.add(
      SongChange(stationSlug: 'linefmrap', track: _song('alt', startMin: -5)),
    );
    await _settle();
    expect(titles.last, 'gleich');

    await sub.cancel();
    r.dispose();
  });

  test('Neuer Titel der aktiven Station rutscht in den Verlauf', () async {
    final r = repo();
    List<HistoryEntry>? history;
    final sub = r.watchHistory(main).listen((h) => history = h);
    await _settle();
    socket.controller.add(
      SongChange(stationSlug: 'linefm', track: _song('neu', startMin: 3)),
    );
    await _settle();
    await _settle();
    expect(history!.first.track.title, 'neu');
    expect(history![1].track.title, 'linefm-1');
    expect(history!.skip(1), hasLength(10));
    await sub.cancel();
    r.dispose();
  });

  test('Polling 60 s im Vordergrund: alle Sender + aktive Details', () async {
    final r = repo();
    final sub = r.watchStations().listen((_) {});
    await _settle();
    api.calls.clear();
    await sched.advance(const Duration(seconds: 60));
    for (final s in stationsCatalog) {
      expect(api.calls, contains('current:${s.slug}'));
    }
    expect(api.calls, contains('last:linefm'));
    expect(api.calls, contains('listeners:linefm'));
    await sub.cancel();
    r.dispose();
  });

  test('Hintergrund ohne Wiedergabe: nichts laeuft, WS zu', () async {
    final r = repo();
    final sub = r.watchStations().listen((_) {});
    await _settle();
    r.setForeground(value: false);
    expect(socket.closes, 1);
    api.calls.clear();
    await sched.advance(const Duration(minutes: 5));
    expect(api.calls, isEmpty);

    // Hintergrund mit Wiedergabe: nur aktive Station.
    r.setPlaying(value: true);
    expect(socket.connects, 2);
    await sched.advance(const Duration(seconds: 60));
    expect(api.calls, isNotEmpty);
    expect(api.calls.every((c) => c == 'current:linefm'), isTrue);

    await sub.cancel();
    r.dispose();
  });

  test('Stationswechsel laedt Details der neuen Station', () async {
    final r = repo();
    final sub = r.watchStations().listen((_) {});
    await _settle();
    api.calls.clear();
    r.setActiveStation(rap);
    await _settle();
    expect(
      api.calls,
      containsAll(<String>[
        'current:linefmrap',
        'last:linefmrap',
        'listeners:linefmrap',
      ]),
    );
    await sub.cancel();
    r.dispose();
  });

  test('Offline-Status und Erholung', () async {
    api.offline = true;
    final r = repo();
    final online = <bool>[];
    final sub = r.watchOnline().listen(online.add);
    await _settle();
    expect(online.last, isFalse);
    api.offline = false;
    await r.refresh();
    await _settle();
    expect(online.last, isTrue);
    await sub.cancel();
    r.dispose();
  });

  test('dispose beendet Timer und Streams', () async {
    final r = repo();
    var done = false;
    r.watchStations().listen((_) {}, onDone: () => done = true);
    await _settle();
    r.dispose();
    await _settle();
    expect(done, isTrue);
    expect(sched.active, 0);
    api.calls.clear();
    await sched.advance(const Duration(minutes: 15));
    expect(api.calls, isEmpty);
  });
}
