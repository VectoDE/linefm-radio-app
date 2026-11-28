import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/alarm/alarm_schedule.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/alarm/alarm_ios.dart';
import 'package:linefm_radio/services/alarm/alarm_texts.dart';

import '../support/test_doubles.dart';
import 'alarm_services_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Mittwoch, 18.11.2026, 06:00.
  final t0 = DateTime(2026, 11, 18, 6);

  group('IosAlarmPlatform', () {
    const channel = MethodChannel(IosAlarmPlatform.channelName);
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return call.method == 'requestPermission' ? true : null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('schedule schickt Zeit, Wochentage, Texte und Deep Link', () async {
      final p = IosAlarmPlatform(texts: AlarmTexts.german);
      await p.schedule(rule(weekdays: <int>{5, 1}, hour: 6, minute: 45));
      expect(calls.map((c) => c.method), <String>[
        'requestPermission',
        'schedule',
      ]);
      final args = calls.last.arguments as Map<Object?, Object?>;
      expect(args['hour'], 6);
      expect(args['minute'], 45);
      expect(args['weekdays'], <int>[1, 5]);
      expect(
        args['url'],
        'linefm://play?station=${stationsCatalog.first.slug}',
      );
      expect(args['title'], 'LINEFM Wecker');
    });

    test('deaktivierte Regel und cancel entfernen die Mitteilungen', () async {
      final p = IosAlarmPlatform();
      await p.schedule(rule(enabled: false));
      expect(calls.single.method, 'cancel');
      expect((calls.single.arguments as Map)['id'], '1700000000000000');
    });

    test('fehlender nativer Kanal wirft nicht', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      final p = IosAlarmPlatform();
      await p.schedule(rule());
      await p.cancel('x');
    });
  });

  group('Befunde der Review', () {
    late FakePlatform platform;
    late FakeClock clock;
    late List<AlarmRule> ruleList;
    late List<AlarmRule> fired;

    setUp(() {
      platform = FakePlatform();
      clock = FakeClock(t0);
      ruleList = <AlarmRule>[rule()];
      fired = <AlarmRule>[];
    });

    int beeps = 0;

    DefaultAlarmCoordinator build(
      Playback playback, {
      Duration streamTimeout = const Duration(milliseconds: 30),
      Duration bannerTimeout = const Duration(minutes: 3),
      Future<void> Function(Station station)? startStation,
    }) => DefaultAlarmCoordinator(
      platform: platform,
      clock: clock,
      playback: playback,
      startStation: startStation ?? playback.playStation,
      rules: () => ruleList,
      onRuleFired: (u) async => fired.add(u),
      rampDuration: Duration.zero,
      streamTimeout: streamTimeout,
      bannerTimeout: bannerTimeout,
      beep: () async => beeps++,
    );

    test('2: geloeschte Regel wird samt Schlummer abgemeldet', () async {
      final c = build(Playback());
      await c.rescheduleAll(<AlarmRule>[rule(id: 'a'), rule(id: 'b')]);
      platform.cancelled.clear();
      await c.rescheduleAll(<AlarmRule>[rule(id: 'a')]);
      expect(platform.cancelled, <String>['b', 'b$snoozeSuffix']);
      expect(platform.orphanCalls.last, <String>{'a'});
      await c.dispose();
    });

    test('2: Speicher loeschen (leere Liste) meldet alles ab', () async {
      final c = build(Playback());
      await c.rescheduleAll(<AlarmRule>[rule(id: 'a')]);
      platform.cancelled.clear();
      await c.rescheduleAll(const <AlarmRule>[]);
      expect(platform.cancelled, contains('a'));
      expect(platform.orphanCalls.last, isEmpty);
      await c.dispose();
    });

    test('3: offline klingelt der Ton weiter, kein cancel', () async {
      final c = build(Playback(autoPlay: false));
      await c.handleRing(AlarmRing(ruleId: ruleList.first.id, handle: 1));
      expect(platform.silenced, isEmpty);
      expect(platform.cancelled, isEmpty);
      expect(fired.single.enabled, isFalse);
      await c.dispose();
    });

    test(
      '4: verpasster Einmal-Wecker wird deaktiviert statt verschoben',
      () async {
        final missed = rule().copyWith(firesAt: DateTime(2026, 11, 18, 5));
        final c = build(Playback());
        await c.rescheduleAll(<AlarmRule>[missed]);
        expect(fired.single.enabled, isFalse);
        expect(platform.scheduled, isEmpty);
        expect(AlarmSchedule.nextOccurrence(missed, t0), isNull);
        await c.dispose();
      },
    );

    test('4: firesAt wird beim Einschalten gesetzt, bei Aenderung neu', () {
      final created = AlarmSchedule.withFiresAt(
        <AlarmRule>[rule()],
        const <AlarmRule>[],
        t0,
      );
      expect(created.single.firesAt, DateTime(2026, 11, 18, 7));
      // Unveraendert: bleibt, auch wenn die Zeit weitergelaufen ist.
      final later = AlarmSchedule.withFiresAt(
        created,
        created,
        DateTime(2026, 11, 18, 8),
      );
      expect(later.single.firesAt, DateTime(2026, 11, 18, 7));
      // Neue Uhrzeit: neuer Termin.
      final moved = AlarmSchedule.withFiresAt(
        <AlarmRule>[created.single.copyWith(hour: 9)],
        created,
        t0,
      );
      expect(moved.single.firesAt, DateTime(2026, 11, 18, 9));
      // Wiederkehrend: kein fester Termin.
      final repeating = AlarmSchedule.withFiresAt(
        <AlarmRule>[
          created.single.copyWith(weekdays: <int>{1}),
        ],
        created,
        t0,
      );
      expect(repeating.single.firesAt, isNull);
      expect(
        AlarmRule.tryFromJson(created.single.toJson())!.firesAt,
        created.single.firesAt,
      );
    });

    test('5: laufender anderer Sender zaehlt nicht als Start', () async {
      final playback = Playback(autoPlay: false);
      await playback.playingOther();
      final c = build(playback);
      await c.handleRing(AlarmRing(ruleId: ruleList.first.id, handle: 1));
      expect(platform.silenced, isEmpty, reason: 'Ziel-Sender spielt nicht');
      await c.dispose();
    });

    test('6: nativ geschlummert: Radio aus, Termin bleibt', () async {
      platform.state = AlarmRingState.snoozed;
      final playback = Playback();
      final c = build(playback, streamTimeout: const Duration(seconds: 5));
      await c.handleRing(AlarmRing(ruleId: ruleList.first.id, handle: 1));
      expect(platform.silenced, isEmpty);
      expect(playback.state.status, PlayerStatus.idle);
      expect(c.ringing.value, isNull);
      await c.dispose();
    });

    test('6: Klingeln zeigt das Banner, Aus raeumt es weg', () async {
      final c = build(Playback());
      await c.handleRing(AlarmRing(ruleId: ruleList.first.id, handle: 1));
      expect(c.ringing.value?.ruleId, ruleList.first.id);
      await c.dismiss(ruleList.first.id);
      expect(c.ringing.value, isNull);
      await c.dispose();
    });

    test('B: Schlummern waehrend des Sendestarts stoppt das Radio', () async {
      final playback = Playback();
      final gate = Completer<void>();
      final c = build(
        playback,
        startStation: (s) async {
          await gate.future;
          await playback.playStation(s);
        },
      );
      final ring = AlarmRing(ruleId: ruleList.first.id, handle: 1);
      final pending = c.handleRing(ring);
      await Future<void>.delayed(Duration.zero);
      await c.snooze(ruleList.first.id);
      gate.complete();
      await pending;
      expect(playback.state.status, PlayerStatus.idle);
      expect(
        playback.volumes.every((v) => v <= 0.2),
        isTrue,
        reason: 'keine Rampe nach Schlummern',
      );
      expect(
        platform.scheduled.any((r) => r.id.endsWith(snoozeSuffix)),
        isTrue,
      );
      await c.dispose();
    });

    test(
      'B: Schlummern waehrend des Wartens: kein Piepton (Desktop)',
      () async {
        platform.itself = false;
        final c = build(Playback(autoPlay: false));
        final pending = c.handleRing(
          AlarmRing(ruleId: ruleList.first.id, handle: 1),
        );
        await Future<void>.delayed(Duration.zero);
        await c.snooze(ruleList.first.id);
        await pending;
        expect(beeps, 0);
        expect(c.ringing.value, isNull);
        await c.dispose();
      },
    );

    test('B: Aus waehrend des Wartens: kein Piepton, Banner weg', () async {
      platform.itself = false;
      final c = build(Playback(autoPlay: false));
      final pending = c.handleRing(
        AlarmRing(ruleId: ruleList.first.id, handle: 1),
      );
      await Future<void>.delayed(Duration.zero);
      await c.dismiss(ruleList.first.id);
      await pending;
      expect(beeps, 0);
      expect(c.ringing.value, isNull);
      await c.dispose();
    });

    test('C: nach Neustart bleibt der Schlummer-Termin bei aus', () async {
      final c1 = build(Playback());
      await c1.rescheduleAll(<AlarmRule>[rule()]);
      await c1.dispose();
      platform.cancelled.clear();
      // Prozess-Neustart: neuer Koordinator ohne Vorzustand.
      final c2 = build(Playback());
      await c2.rescheduleAll(<AlarmRule>[rule(enabled: false)]);
      expect(platform.cancelled, isEmpty);
      await c2.dispose();
    });

    test('C: Nutzer schaltet aus: Schlummer-Termin entfaellt', () async {
      final c = build(Playback());
      await c.rescheduleAll(<AlarmRule>[rule()]);
      await c.rescheduleAll(<AlarmRule>[rule(enabled: false)]);
      expect(platform.cancelled, <String>['${rule().id}$snoozeSuffix']);
      await c.dispose();
    });

    test(
      'D: ohne Stream bleiben Banner und Piepton ueber das Timeout',
      () async {
        platform.itself = false;
        final c = build(
          Playback(autoPlay: false),
          bannerTimeout: const Duration(milliseconds: 40),
        );
        await c.handleRing(AlarmRing(ruleId: ruleList.first.id, handle: 1));
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(c.ringing.value, isNotNull);
        expect(beeps, greaterThan(0));
        await c.dismiss(ruleList.first.id);
        expect(c.ringing.value, isNull);
        await c.dispose();
      },
    );

    test('D: laeuft der Stream, blendet sich das Banner aus', () async {
      final c = build(
        Playback(),
        bannerTimeout: const Duration(milliseconds: 40),
      );
      await c.handleRing(AlarmRing(ruleId: ruleList.first.id, handle: 1));
      expect(c.ringing.value, isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(c.ringing.value, isNull);
      await c.dispose();
    });

    test('13: dispose des Koordinators entsorgt die Plattform', () async {
      final c = build(Playback());
      await c.dispose();
      expect(platform.disposed, isTrue);
    });
  });
}
