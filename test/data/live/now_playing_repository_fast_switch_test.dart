import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/data/api/song_change_socket.dart';
import 'package:linefm_radio/data/live/now_playing_repository.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';

import '../../support/service_doubles.dart';
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

  test('dispose beendet Timer und Streams', () async {
    final r = repo();
    var done = false;
    r.watchStations().listen((_) {}, onDone: () => done = true);
    await settle();
    r.dispose();
    await settle();
    expect(done, isTrue);
    expect(sched.active, 0);
    api.calls.clear();
    await sched.advance(const Duration(minutes: 15));
    expect(api.calls, isEmpty);
  });

  group('schneller Senderwechsel', () {
    test(
      'verspaetete Antwort des alten Senders aendert den neuen nicht',
      () async {
        final api = GatedApi()
          ..current.addAll(<String, Track?>{
            for (final s in stationsCatalog) s.slug: song('${s.slug}-1'),
          });
        final r = LiveNowPlayingRepository(
          artwork: const NoopArtworkService(),
          api: api,
          clock: clock,
          timer: sched.one,
          periodicTimer: sched.periodic,
        );
        final third = stationsCatalog[2];
        final seen = <String, Track?>{};
        final subs = <StreamSubscription<Object?>>[
          for (final s in [main, rap, third])
            r.watchTrack(s).listen((t) => seen[s.slug] = t),
        ];
        await settle();
        expect(seen[third.slug]?.title, '${third.slug}-1');

        // Ab jetzt haengen alle Antworten, bis der Test sie freigibt.
        api.gated = true;
        clock.setTo(t0.add(const Duration(minutes: 1)));
        r
          ..setActiveStation(rap)
          ..setActiveStation(third)
          ..setActiveStation(rap)
          ..setActiveStation(third);
        await settle();
        expect(api.pending.keys, containsAll(<String>['current:${rap.slug}']));

        // Neuer Sender antwortet zuerst, der alte erst danach.
        api.release(
          'current:${third.slug}',
          song('${third.slug}-2', startMin: 1),
        );
        await settle();
        api.release(
          'current:${rap.slug}',
          song('${rap.slug}-2', startMin: 1, lengthSec: 600),
        );
        await settle();
        // Restliche Antworten (Verlauf, Hoerer) freigeben.
        for (final key in api.pending.keys.toList()) {
          api.release(key, null);
        }
        await settle();

        expect(seen[third.slug]?.title, '${third.slug}-2');
        expect(seen[rap.slug]?.title, '${rap.slug}-2');
        // ends_at-Timer gilt dem aktiven Sender (third-2, 180 s), nicht der
        // verspaeteten Antwort von rap (600 s).
        final thirdEnd = seen[third.slug]!.endsAt!;
        expect(
          r.lastEndsAtDelay,
          thirdEnd.add(const Duration(seconds: 3)).difference(clock.now()),
        );

        for (final s in subs) {
          await s.cancel();
        }
        r.dispose();
      },
    );

    test('abgelaufener Titel des neuen Senders wird sofort neutral', () async {
      final api = GatedApi()
        ..current.addAll(<String, Track?>{
          for (final s in stationsCatalog) s.slug: song('${s.slug}-1'),
        });
      final r = LiveNowPlayingRepository(
        artwork: const NoopArtworkService(),
        api: api,
        clock: clock,
        timer: sched.one,
        periodicTimer: sched.periodic,
      );
      Track? rapTrack;
      final sub = r.watchTrack(rap).listen((t) => rapTrack = t);
      await settle();
      expect(rapTrack?.title, '${rap.slug}-1');

      // rap-1 endete um Minute 3; die App war lange auf einem anderen Sender.
      api.gated = true;
      clock.setTo(t0.add(const Duration(minutes: 20)));
      r.setActiveStation(rap);
      await settle();
      expect(rapTrack, isNull, reason: 'kein Titel vom Stand vor 17 Minuten');

      api.release('current:${rap.slug}', song('${rap.slug}-9', startMin: 19));
      await settle();
      expect(rapTrack?.title, '${rap.slug}-9');

      await sub.cancel();
      r.dispose();
    });

    test('Socket-Ereignis des alten Senders aendert den Titel des neuen '
        'nicht', () async {
      final r = repo();
      final seen = <String, List<String?>>{
        main.slug: <String?>[],
        rap.slug: <String?>[],
      };
      final subs = <StreamSubscription<Object?>>[
        for (final s in [main, rap])
          r.watchTrack(s).listen((t) => seen[s.slug]!.add(t?.title)),
      ];
      await settle();

      // Wechsel A (linefm) -> B (linefmrap).
      r.setActiveStation(rap);
      await settle();
      final delayForB = r.lastEndsAtDelay;
      final shownForB = seen[rap.slug]!.last;
      expect(shownForB, '${rap.slug}-1');
      final emissionsForB = seen[rap.slug]!.length;

      // Sofortiges Ereignis fuer A: nur A aendert sich, B bleibt unberuehrt
      // und der ends_at-Timer gilt weiter B.
      socket.controller.add(
        SongChange(
          stationSlug: main.slug,
          track: song('A-neu', lengthSec: 900),
        ),
      );
      await settle();
      expect(seen[main.slug]!.last, 'A-neu');
      expect(seen[rap.slug]!.last, shownForB);
      expect(seen[rap.slug]!.sublist(emissionsForB - 1).toSet(), <String?>{
        shownForB,
      });
      expect(r.lastEndsAtDelay, delayForB);

      // Angekuendigtes Ereignis fuer A (kommt erst nach Start an): auch dann
      // bleibt B stehen und der Timer von B unveraendert.
      socket.controller.add(
        SongChange(
          stationSlug: main.slug,
          track: Track(
            artist: 'Artist',
            title: 'A-gleich',
            startedAt: clock.now().add(const Duration(seconds: 7)),
            endsAt: clock.now().add(const Duration(minutes: 20)),
          ),
        ),
      );
      await settle();
      await sched.advance(const Duration(seconds: 7));
      expect(seen[main.slug]!.last, 'A-gleich');
      expect(seen[rap.slug]!.last, shownForB);
      expect(seen[rap.slug]!.sublist(emissionsForB - 1).toSet(), <String?>{
        shownForB,
      });
      expect(r.lastEndsAtDelay, delayForB);

      // Gegenprobe: ein Ereignis fuer B wird weiterhin angezeigt.
      socket.controller.add(
        SongChange(stationSlug: rap.slug, track: song('B-neu')),
      );
      await settle();
      expect(seen[rap.slug]!.last, 'B-neu');

      for (final s in subs) {
        await s.cancel();
      }
      r.dispose();
    });
  });

  test('every history entry gets its own cover, misses keep the '
      'station logo fallback', () async {
    artwork.misses.addAll(<String>{'alt2', 'alt5'});
    final r = repo();
    List<HistoryEntry>? history;
    final sub = r.watchHistory(main).listen((v) => history = v);
    await settle();

    final past = history!.where((h) => !h.isLive).toList();
    expect(past, hasLength(10));
    for (final entry in past) {
      final title = entry.track.title;
      if (artwork.misses.contains(title)) {
        expect(entry.track.artworkUrl, isNull, reason: title);
      } else {
        expect(
          entry.track.artworkUrl,
          'https://cover/$title.jpg',
          reason: title,
        );
      }
    }
    // No two entries share an image.
    final urls = past.map((e) => e.track.artworkUrl).whereType<String>();
    expect(urls.toSet(), hasLength(urls.length));
    // The live entry keeps its own cover, not one from the history.
    expect(history!.first.track.artworkUrl, 'https://cover/linefm-1.jpg');

    await sub.cancel();
    r.dispose();
  });

  test('a reloaded history keeps covers already found', () async {
    final r = repo();
    List<HistoryEntry>? history;
    final sub = r.watchHistory(main).listen((v) => history = v);
    await settle();
    artwork.misses.add('alt1');
    await sched.advance(const Duration(minutes: 2));

    final alt1 = history!.firstWhere((h) => h.track.title == 'alt1');
    expect(alt1.track.artworkUrl, 'https://cover/alt1.jpg');

    await sub.cancel();
    r.dispose();
  });
}
