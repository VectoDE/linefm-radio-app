import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/services/alarm/alarm_android.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/alarm/alarm_permissions.dart';
import 'package:linefm_radio/services/alarm/alarm_texts.dart';

import '../support/test_doubles.dart';
import 'alarm_services_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Mittwoch, 18.11.2026, 06:00.
  final t0 = DateTime(2026, 11, 18, 6);

  group('AndroidAlarmPlatform (Review)', () {
    late FakeAlarmApi api;
    late AndroidAlarmPlatform platform;

    setUp(() {
      api = FakeAlarmApi();
      platform = AndroidAlarmPlatform(
        clock: FakeClock(t0),
        api: api,
        texts: AlarmTexts.german,
      );
    });

    test('A: belegte ID kostet keinen Termin, naechste freie Nummer', () async {
      final daily = rule(weekdays: <int>{1, 2, 3, 4, 5, 6, 7});
      await platform.schedule(daily);
      final today = DateTime(2026, 11, 18, 7);
      final first = AndroidAlarmPlatform.idFor(daily.id, 0);
      expect(api.alarms[first]?.dateTime, today);
      final before = api.alarms.length;
      api.ringingIds.add(first); // klingelt oder geschlummert: ID belegt
      await platform.schedule(daily);
      final atToday = api.alarms.values.where((a) => a.dateTime == today);
      expect(atToday.length, 2, reason: 'Termin heute behaelt eine freie ID');
      expect(
        api.alarms.values.any((a) => a.dateTime == DateTime(2026, 11, 19, 7)),
        isTrue,
        reason: 'Folgetag faellt nicht aus',
      );
      expect(api.alarms.length, before + 1);
    });

    test('2: verwaiste Alarme ohne Regel werden gestoppt', () async {
      await platform.schedule(rule(id: 'keep'));
      await platform.schedule(rule(id: 'weg'));
      await platform.schedule(rule(id: 'x$snoozeSuffix'));
      await platform.removeOrphans(<String>{'keep', 'x'});
      expect(api.alarms.values.map((a) => a.payload).toSet(), <String?>{
        'keep',
        'x$snoozeSuffix',
      });
    });

    test('3: ausgeschaltete Regel stoppt keinen klingelnden Alarm', () async {
      await platform.schedule(rule(weekdays: <int>{3}));
      final ringingId = api.alarms.keys.first;
      api.ringingIds.add(ringingId);
      await platform.schedule(rule(weekdays: <int>{3}, enabled: false));
      expect(api.alarms.keys, <int>[ringingId]);
    });

    test('6: nativ geschlummerter Termin bleibt beim Neuplanen', () async {
      await platform.init();
      await platform.schedule(rule());
      final id = api.alarms.keys.single;
      api.snoozedController.add((id, DateTime(2026, 11, 18, 7, 9)));
      await Future<void>.delayed(Duration.zero);
      await platform.schedule(rule(enabled: false));
      expect(api.alarms.keys, <int>[id]);
    });

    test('6: silence stoppt nur, solange er klingelt', () async {
      await platform.schedule(rule());
      final id = api.alarms.keys.single;
      final ring = AlarmRing(ruleId: rule().id, handle: id);
      await platform.silence(ring); // nicht klingelnd: nichts loeschen
      expect(api.alarms, isNotEmpty);
      api.ringingIds.add(id);
      await platform.silence(ring);
      expect(api.alarms, isEmpty);
    });

    test(
      '6: ringState unterscheidet klingelnd, geschlummert, beendet',
      () async {
        await platform.schedule(rule());
        final id = api.alarms.keys.single;
        final ring = AlarmRing(ruleId: rule().id, handle: id);
        expect(await platform.ringState(ring), AlarmRingState.snoozed);
        api.ringingIds.add(id);
        expect(await platform.ringState(ring), AlarmRingState.ringing);
        api.ringingIds.clear();
        api.alarms.clear();
        expect(await platform.ringState(ring), AlarmRingState.ended);
      },
    );
  });

  group('Berechtigungen', () {
    test('Nicht-Android: immer erlaubt, keine Rueckfrage', () async {
      final g = Gateway(exact: false);
      expect(await alarmPermissionCheck(g, isAndroid: false), isTrue);
      expect(g.notificationRequests, 0);
    });

    test('Android ohne Freigabe: false, Mitteilungen werden erfragt', () async {
      final g = Gateway(exact: false);
      expect(await alarmPermissionCheck(g, isAndroid: true), isFalse);
      expect(g.notificationRequests, 1);
    });

    test('Android mit Freigabe: true', () async {
      expect(
        await alarmPermissionCheck(Gateway(exact: true), isAndroid: true),
        isTrue,
      );
    });

    test('Systemeinstellung oeffnet nur auf Android', () async {
      final g = Gateway(exact: false);
      await alarmOpenSystemSettings(g, isAndroid: false);
      expect(g.opened, 0);
      await alarmOpenSystemSettings(g, isAndroid: true);
      expect(g.opened, 1);
    });
  });
}
