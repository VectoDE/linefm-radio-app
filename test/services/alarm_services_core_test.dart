import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/services/alarm/alarm_android.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/alarm/alarm_inapp.dart';
import 'package:linefm_radio/services/alarm/alarm_texts.dart';

import '../support/test_doubles.dart';
import 'alarm_services_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Mittwoch, 18.11.2026, 06:00.
  final t0 = DateTime(2026, 11, 18, 6);

  group('AndroidAlarmPlatform', () {
    late FakeAlarmApi api;
    late FakeClock clock;
    late AndroidAlarmPlatform platform;

    setUp(() {
      api = FakeAlarmApi();
      clock = FakeClock(t0);
      platform = AndroidAlarmPlatform(
        clock: clock,
        api: api,
        texts: AlarmTexts.german,
      );
    });

    test('einmaliger Wecker plant genau einen Termin mit Systemton', () async {
      await platform.schedule(rule());
      expect(api.alarms, hasLength(1));
      final a = api.alarms.values.single;
      expect(a.dateTime, DateTime(2026, 11, 18, 7));
      expect(a.assetAudioPath, isNull, reason: 'Entscheidung 40: Systemton');
      expect(a.payload, '1700000000000000');
      expect(a.androidSnoozeDuration, const Duration(minutes: 9));
      expect(a.androidFullScreenIntent, isTrue);
      expect(a.androidStopAlarmOnTermination, isFalse);
      expect(a.androidAlarmClock, isTrue);
    });

    test('Wochentage: Termine der naechsten 21 Tage, eindeutige IDs', () async {
      // Mo und Fr
      await platform.schedule(rule(weekdays: <int>{1, 5}));
      final times = api.alarms.values.map((a) => a.dateTime).toList()..sort();
      expect(times.first, DateTime(2026, 11, 20, 7)); // Freitag
      expect(times, hasLength(6)); // 20., 23., 27., 30.11., 4., 7.12.
      expect(times.every((t) => t.hour == 7 && t.minute == 0), isTrue);
      expect(api.alarms.keys.toSet(), hasLength(6));
      expect(api.alarms.keys.map(AndroidAlarmPlatform.keyOfId).toSet(), <int>{
        AndroidAlarmPlatform.keyOf('1700000000000000'),
      });
    });

    test('erneutes Planen ersetzt statt zu verdoppeln', () async {
      await platform.schedule(rule(weekdays: <int>{1, 5}));
      await platform.schedule(rule(weekdays: <int>{1, 5}, hour: 8));
      expect(api.alarms, hasLength(6));
      expect(api.alarms.values.every((a) => a.dateTime.hour == 8), isTrue);
    });

    test('deaktivierte Regel plant nichts und raeumt auf', () async {
      await platform.schedule(rule());
      await platform.schedule(rule(enabled: false));
      expect(api.alarms, isEmpty);
    });

    test('Planen verschont einen klingelnden Alarm der Regel', () async {
      await platform.schedule(rule(weekdays: <int>{3}));
      final ringingId = api.alarms.keys.first;
      api.ringingIds.add(ringingId);
      await platform.schedule(rule(weekdays: <int>{3}));
      expect(api.alarms.containsKey(ringingId), isTrue);
      // neue Termine bekommen andere IDs
      expect(api.alarms.length, greaterThan(1));
    });

    test('cancel entfernt alle Termine der Regel, andere bleiben', () async {
      await platform.schedule(rule(weekdays: <int>{1, 5}));
      await platform.schedule(rule(id: '42'));
      await platform.cancel('1700000000000000');
      expect(api.alarms.values.map((a) => a.payload).toSet(), <String?>{'42'});
    });

    test('meldet klingelnde Alarme mit Regel-ID aus der Nutzlast', () async {
      final got = <AlarmRing>[];
      final sub = platform.rings.listen(got.add);
      await platform.schedule(rule());
      api.ringingController.add(api.alarms.values.toList());
      await Future<void>.delayed(Duration.zero);
      expect(got.single.ruleId, '1700000000000000');
      expect(got.single.handle, api.alarms.keys.single);
      await sub.cancel();
      api.ringingIds.add(got.single.handle!);
      await platform.silence(got.single);
      expect(api.alarms, isEmpty);
    });
  });

  group('InAppAlarmPlatform', () {
    late FakeClock clock;
    late InAppAlarmPlatform platform;
    late List<AlarmRing> rings;
    late StreamSubscription<AlarmRing> sub;

    setUp(() {
      clock = FakeClock(t0);
      platform = InAppAlarmPlatform(clock: clock);
      rings = <AlarmRing>[];
      sub = platform.rings.listen(rings.add);
    });

    tearDown(() async {
      await sub.cancel();
      await platform.dispose();
    });

    Future<void> pump() => Future<void>.delayed(Duration.zero);

    test('klingelt, sobald die Uhrzeit erreicht ist, genau einmal', () async {
      await platform.schedule(rule());
      clock.setTo(DateTime(2026, 11, 18, 6, 59, 50));
      platform.check();
      await pump();
      expect(rings, isEmpty);
      clock.setTo(DateTime(2026, 11, 18, 7, 0, 5));
      platform.check();
      await pump();
      expect(rings.single.ruleId, '1700000000000000');
      clock.setTo(DateTime(2026, 11, 18, 7, 0, 20));
      platform.check();
      await pump();
      expect(rings, hasLength(1), reason: 'einmalig: kein zweites Klingeln');
    });

    test(
      'faengt einen Ruhezustand ab (Termin zwischen zwei Pruefungen)',
      () async {
        await platform.schedule(rule(weekdays: <int>{3}));
        clock.setTo(DateTime(2026, 11, 18, 9)); // zwei Stunden spaeter
        platform.check();
        await pump();
        expect(rings, hasLength(1));
      },
    );

    test(
      'neu gestellter Wecker klingelt nicht fuer die Vergangenheit',
      () async {
        clock.setTo(DateTime(2026, 11, 18, 8)); // 07:00 ist schon vorbei
        await platform.schedule(rule());
        clock.setTo(DateTime(2026, 11, 18, 8, 0, 15));
        platform.check();
        await pump();
        expect(rings, isEmpty);
      },
    );

    test('wiederkehrend klingelt am naechsten passenden Tag erneut', () async {
      await platform.schedule(rule(weekdays: <int>{3, 4}));
      clock.setTo(DateTime(2026, 11, 18, 7, 0, 5));
      platform.check();
      clock.setTo(DateTime(2026, 11, 19, 7, 0, 5));
      platform.check();
      await pump();
      expect(rings, hasLength(2));
    });

    test('cancel stoppt den Wecker', () async {
      await platform.schedule(rule());
      await platform.cancel('1700000000000000');
      clock.setTo(DateTime(2026, 11, 18, 7, 1));
      platform.check();
      await pump();
      expect(rings, isEmpty);
    });
  });

  group('DefaultAlarmCoordinator', () {
    late FakePlatform platform;
    late FakeClock clock;
    late List<AlarmRule> ruleList;
    late List<AlarmRule> fired;
    late List<Station> startedByApp;

    setUp(() {
      platform = FakePlatform();
      clock = FakeClock(t0);
      ruleList = <AlarmRule>[rule()];
      fired = <AlarmRule>[];
      startedByApp = <Station>[];
    });

    DefaultAlarmCoordinator build(
      Playback playback, {
      Duration streamTimeout = const Duration(seconds: 45),
    }) => DefaultAlarmCoordinator(
      platform: platform,
      clock: clock,
      playback: playback,
      startStation: (s) async {
        startedByApp.add(s);
        await playback.playStation(s);
      },
      rules: () => ruleList,
      onRuleFired: (u) async => fired.add(u),
      rampDuration: Duration.zero,
      streamTimeout: streamTimeout,
    );

    test(
      'Klingeln: Sender startet, Ton endet erst bei laufendem Stream',
      () async {
        final playback = Playback();
        final c = build(playback);
        final ring = AlarmRing(ruleId: ruleList.first.id, handle: 5, at: t0);
        await c.handleRing(ring);
        expect(startedByApp.single, stationsCatalog.first);
        expect(platform.silenced.single, ring);
        expect(playback.volumes.first, 0.2, reason: 'Rampe startet leise');
        expect(playback.volumes.last, 0.7, reason: 'Rampe endet am Zielwert');
        await c.dispose();
      },
    );

    test('einmaliger Wecker schaltet sich nach dem Klingeln aus', () async {
      final c = build(Playback());
      await c.handleRing(AlarmRing(ruleId: ruleList.first.id, handle: 1));
      expect(fired.single.enabled, isFalse);
      expect(
        platform.cancelled,
        isEmpty,
        reason: 'kein cancel: ein klingelnder Ton darf nicht verstummen',
      );
      await c.dispose();
    });

    test('wiederkehrender Wecker plant neu und bleibt aktiv', () async {
      ruleList = <AlarmRule>[
        rule(weekdays: <int>{3}),
      ];
      final c = build(Playback());
      await c.handleRing(AlarmRing(ruleId: ruleList.first.id, handle: 1));
      expect(fired, isEmpty);
      expect(platform.scheduled.single, ruleList.first);
      await c.dispose();
    });

    test('Stream laeuft nicht an: Weckton klingelt weiter', () async {
      final c = build(
        Playback(autoPlay: false),
        streamTimeout: const Duration(milliseconds: 30),
      );
      await c.handleRing(AlarmRing(ruleId: ruleList.first.id, handle: 1));
      expect(platform.silenced, isEmpty, reason: 'kein stilles Verschlafen');
      await c.dispose();
    });

    test('Stream laeuft spaeter an: Ton endet dann', () async {
      final playback = Playback(autoPlay: false);
      final c = build(playback);
      final done = c.handleRing(
        AlarmRing(ruleId: ruleList.first.id, handle: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(platform.silenced, isEmpty);
      await playback.playingNow();
      await done;
      expect(platform.silenced, hasLength(1));
      await c.dispose();
    });

    test('doppelt gemeldetes Klingeln wird nur einmal verarbeitet', () async {
      final c = build(Playback());
      final ring = AlarmRing(ruleId: ruleList.first.id, handle: 1, at: t0);
      await c.handleRing(ring);
      await c.handleRing(ring);
      expect(startedByApp, hasLength(1));
      await c.dispose();
    });

    test('Regel inzwischen geloescht: Ton wird beendet, kein Sender', () async {
      ruleList = <AlarmRule>[];
      final c = build(Playback());
      await c.handleRing(const AlarmRing(ruleId: 'weg', handle: 9));
      expect(startedByApp, isEmpty);
      expect(platform.silenced, hasLength(1));
      await c.dispose();
    });

    test(
      'rescheduleAll plant aktive und entfernt deaktivierte Regeln',
      () async {
        final c = build(Playback());
        await c.rescheduleAll(<AlarmRule>[
          rule(id: 'a'),
          rule(id: 'b', enabled: false),
        ]);
        expect(platform.scheduled.map((r) => r.id), <String>['a', 'b']);
        expect(platform.cancelled, isEmpty);
        await c.dispose();
      },
    );

    test('Schlummern: Wiedergabe stoppt, Wiederholung in 9 Minuten', () async {
      clock.setTo(DateTime(2026, 11, 18, 7, 0, 20));
      ruleList = <AlarmRule>[rule(enabled: false)]; // einmalig schon gefeuert
      final playback = Playback();
      await playback.playStation(stationsCatalog.first);
      final c = build(playback);
      await c.snooze(ruleList.first.id);
      expect(playback.state.status, PlayerStatus.idle);
      final snoozed = platform.scheduled.single;
      expect(snoozed.id, '${ruleList.first.id}$snoozeSuffix');
      expect(snoozed.enabled, isTrue);
      expect(snoozed.repeats, isFalse);
      // 07:00:20 + 9 min = 07:09:20, aufgerundet auf die volle Minute.
      expect(snoozed.hour, 7);
      expect(snoozed.minute, 10);
      await c.dispose();
    });

    test(
      'Klingeln einer Schlummer-Wiederholung nutzt die Basisregel',
      () async {
        final c = build(Playback());
        await c.handleRing(
          AlarmRing(ruleId: '${ruleList.first.id}$snoozeSuffix', handle: 3),
        );
        expect(startedByApp, hasLength(1));
        expect(fired, isEmpty, reason: 'Basisregel wurde schon behandelt');
        await c.dispose();
      },
    );

    test('dismiss entfernt Schlummer und plant Wiederkehrende neu', () async {
      ruleList = <AlarmRule>[
        rule(weekdays: <int>{3}),
      ];
      final c = build(Playback());
      await c.snooze(ruleList.first.id);
      platform.scheduled.clear();
      await c.dismiss(ruleList.first.id);
      expect(platform.cancelled, contains('${ruleList.first.id}$snoozeSuffix'));
      expect(platform.scheduled.single, ruleList.first);
      await c.dispose();
    });
  });
}
