import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/data/api/song_change_socket.dart';
import 'package:linefm_radio/data/live/now_playing_repository.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/now_playing.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';

import '../../support/test_doubles.dart';
import 'now_playing_repository_helpers.dart';

void main() {
  final main = stationsCatalog.first; // linefm
  final rap = stationsCatalog[1];

  late FakeApi api;
  late FakeSocket socket;
  late FakeArtwork artwork;
  late FakeClock clock;
  late Scheduler sched;

  setUp(() {
    api = FakeApi();
    socket = FakeSocket();
    artwork = FakeArtwork();
    clock = FakeClock(t0.add(const Duration(seconds: 30)));
    sched = Scheduler(clock);
    for (final s in stationsCatalog) {
      api.current[s.slug] = song('${s.slug}-1');
    }
    api.last['linefm'] = <Track>[
      song('linefm-1'),
      for (var i = 1; i <= 10; i++) song('alt$i', startMin: -3 * i),
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
    await settle();

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

  test('Start: jede Adresse nur einmal, auch bei Vordergrund-Wechsel und '
      'Stationswechsel', () async {
    final r = repo();
    final subs = <StreamSubscription<Object?>>[
      r.watchStations().listen((_) {}),
      r.watchHistory(main).listen((_) {}),
      r.watchListeners(main).listen((_) {}),
      r.watchTrack(main).listen((_) {}),
    ];
    await settle();
    // Typische Ausloeser direkt nach dem Start: Fenster verliert/erhaelt den
    // Fokus (AppLifecycle), Stationswechsel durch Link oder gemerkte Station.
    r.setForeground(value: false);
    r.setForeground(value: true);
    r.setActiveStation(rap);
    r.setActiveStation(main);
    await settle();

    int count(String call) => api.calls.where((c) => c == call).length;
    expect(count('current:linefm'), 1);
    expect(count('last:linefm'), 1);
    expect(count('listeners:linefm'), 1);
    expect(count('current:linefmrap'), 1);
    expect(count('last:linefmrap'), 1);
    expect(count('listeners:linefmrap'), 1);

    // Nach dem Mindestabstand wird wieder abgerufen.
    clock.advance(const Duration(seconds: 6));
    r.setForeground(value: false);
    r.setForeground(value: true);
    await settle();
    expect(count('current:linefm'), 2);

    // Pull-to-refresh umgeht den Abstand.
    await r.refresh();
    expect(count('current:linefm'), 3);

    for (final s in subs) {
      await s.cancel();
    }
    r.dispose();
  });

  test('ends_at-Timer: Abruf bei ends_at + 3 s, Grenzen 10 s/10 min', () async {
    final r = repo();
    final sub = r.watchTrack(main).listen((_) {});
    await settle();
    // Song endet bei t0+180 s, jetzt t0+30 s -> 153 s.
    expect(r.lastEndsAtDelay, const Duration(seconds: 153));

    api.current['linefm'] = song('linefm-2', startMin: 3);
    api.calls.clear();
    await sched.advance(const Duration(seconds: 153));
    expect(api.calls, contains('current:linefm'));

    // Ende in der Vergangenheit -> Minimum 10 s.
    api.current['linefm'] = song('linefm-3', startMin: 4);
    clock.advance(const Duration(minutes: 10));
    await r.refresh();
    expect(r.lastEndsAtDelay, const Duration(seconds: 10));

    // Live-Sendung ohne Ende -> 30 s.
    api.current['linefm'] = song('live', startMin: 12, lengthSec: null);
    await r.refresh();
    expect(r.lastEndsAtDelay, const Duration(seconds: 30));

    // Sehr langes Ende -> Maximum 10 min.
    api.current['linefm'] = song('lang', startMin: 20, lengthSec: 3600);
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
    await settle();
    expect(titles.last, 'linefmrap-1');

    socket.controller.add(
      SongChange(stationSlug: 'linefmrap', track: song('jetzt')),
    );
    await settle();
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
    await settle();
    expect(titles.last, 'jetzt');
    await sched.advance(const Duration(seconds: 7));
    expect(titles.last, 'gleich');

    // Veraltete Antwort (frueherer Start) wird ignoriert.
    socket.controller.add(
      SongChange(stationSlug: 'linefmrap', track: song('alt', startMin: -5)),
    );
    await settle();
    expect(titles.last, 'gleich');

    await sub.cancel();
    r.dispose();
  });

  test('Neuer Titel der aktiven Station rutscht in den Verlauf', () async {
    final r = repo();
    List<HistoryEntry>? history;
    final sub = r.watchHistory(main).listen((h) => history = h);
    await settle();
    socket.controller.add(
      SongChange(stationSlug: 'linefm', track: song('neu', startMin: 3)),
    );
    await settle();
    await settle();
    expect(history!.first.track.title, 'neu');
    expect(history![1].track.title, 'linefm-1');
    expect(history!.skip(1), hasLength(10));
    await sub.cancel();
    r.dispose();
  });

  test('Polling 60 s im Vordergrund: alle Sender + aktive Details', () async {
    final r = repo();
    final sub = r.watchStations().listen((_) {});
    await settle();
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
    await settle();
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
    await settle();
    // Nach dem Mindestabstand (sonst waere der Titel noch frisch genug).
    clock.advance(const Duration(seconds: 6));
    api.calls.clear();
    r.setActiveStation(rap);
    await settle();
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
    await settle();
    expect(online.last, isFalse);
    api.offline = false;
    await r.refresh();
    await settle();
    expect(online.last, isTrue);
    await sub.cancel();
    r.dispose();
  });
}
