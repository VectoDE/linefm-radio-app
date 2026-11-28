import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/alarm/alarm_schedule.dart';

import '../support/test_doubles.dart';
import 'alarm_schedule_helpers.dart';

void main() {
  // 18.11.2026 ist ein Mittwoch.
  final wed = DateTime(2026, 11, 18, 12);

  group('Schlummern', () {
    test('9 Minuten', () {
      expect(AlarmSchedule.snooze, const Duration(minutes: 9));
      expect(
        AlarmSchedule.snoozeUntil(DateTime(2026, 11, 18, 7)),
        DateTime(2026, 11, 18, 7, 9),
      );
    });

    test('ueber Mitternacht', () {
      expect(
        AlarmSchedule.snoozeUntil(DateTime(2026, 11, 18, 23, 55)),
        DateTime(2026, 11, 19, 0, 4),
      );
    });

    test('mit FakeClock', () {
      final clock = FakeClock(DateTime(2026, 11, 18, 6, 59));
      final fire = AlarmSchedule.nextOccurrence(rule(), clock.now())!;
      clock.setTo(fire);
      final again = AlarmSchedule.snoozeUntil(clock.now());
      expect(again, DateTime(2026, 11, 18, 7, 9));
    });
  });

  group('Faelligkeit (Desktop-Timer)', () {
    final r = rule();

    test('klingelt im Pruefintervall (exklusiv/inklusiv)', () {
      expect(
        AlarmSchedule.isDue(
          r,
          previousCheck: DateTime(2026, 11, 19, 6, 59, 50),
          now: DateTime(2026, 11, 19, 7, 0, 5),
        ),
        isTrue,
      );
      expect(
        AlarmSchedule.isDue(
          r,
          previousCheck: DateTime(2026, 11, 19, 6, 59, 45),
          now: DateTime(2026, 11, 19, 7),
        ),
        isTrue,
      );
    });

    test('Zeitpunkt = previousCheck zaehlt nicht doppelt', () {
      expect(
        AlarmSchedule.isDue(
          r,
          previousCheck: DateTime(2026, 11, 19, 7),
          now: DateTime(2026, 11, 19, 7, 0, 15),
        ),
        isFalse,
      );
    });

    test('vor der Uhrzeit nicht faellig', () {
      expect(
        AlarmSchedule.isDue(
          r,
          previousCheck: DateTime(2026, 11, 19, 6, 59),
          now: DateTime(2026, 11, 19, 6, 59, 15),
        ),
        isFalse,
      );
    });

    test('nach Ruhezustand: verpasster Wecker ist faellig', () {
      expect(
        AlarmSchedule.isDue(
          r,
          previousCheck: DateTime(2026, 11, 19, 1),
          now: DateTime(2026, 11, 19, 7, 30),
        ),
        isTrue,
      );
    });

    test('deaktiviert nie faellig', () {
      expect(
        AlarmSchedule.isDue(
          rule(enabled: false),
          previousCheck: DateTime(2026, 11, 19, 1),
          now: DateTime(2026, 11, 19, 8),
        ),
        isFalse,
      );
    });
  });

  group('mehrere Regeln und Nachbehandlung', () {
    test('nextOf liefert die fruehste Zeit und ignoriert deaktivierte', () {
      final rules = <AlarmRule>[
        rule(hour: 9).copyWith(id: 'a'),
        rule(hour: 15).copyWith(id: 'b'),
        rule(hour: 13, enabled: false).copyWith(id: 'c'),
      ];
      expect(AlarmSchedule.nextOf(rules, wed), DateTime(2026, 11, 18, 15));
      expect(AlarmSchedule.nextOf(<AlarmRule>[], wed), isNull);
      expect(
        AlarmSchedule.nextOf(<AlarmRule>[rule(enabled: false)], wed),
        isNull,
      );
    });

    test('einmaliger Wecker schaltet sich nach dem Klingeln aus', () {
      expect(AlarmSchedule.afterFired(rule()).enabled, isFalse);
    });

    test('wiederkehrender Wecker bleibt aktiv', () {
      final repeating = rule(weekdays: <int>{1, 2});
      expect(AlarmSchedule.afterFired(repeating), repeating);
    });
  });

  group('AlarmRule', () {
    test('JSON-Rundlauf, Wochentage sortiert', () {
      const r = AlarmRule(
        id: 'x',
        hour: 6,
        minute: 30,
        stationSlug: 'fobfm',
        weekdays: <int>{5, 1, 3},
        volume: 0.6,
        enabled: false,
      );
      expect(r.toJson()['weekdays'], <int>[1, 3, 5]);
      expect(AlarmRule.tryFromJson(r.toJson()), r);
    });

    test('Wertgleichheit ignoriert die Reihenfolge der Wochentage', () {
      final a = rule(weekdays: <int>{1, 2});
      final b = rule(weekdays: <int>{2, 1});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(a.copyWith(minute: 1)));
      expect(a, isNot(a.copyWith(volume: 0.5)));
      expect(a.toString(), contains('07:00'));
    });

    test('kaputte oder unvollstaendige Daten ergeben null, nicht Absturz', () {
      expect(AlarmRule.tryFromJson(null), isNull);
      expect(AlarmRule.tryFromJson('x'), isNull);
      expect(AlarmRule.tryFromJson(<String, Object?>{}), isNull);
      const ok = <String, Object?>{
        'id': 'a',
        'hour': 7,
        'minute': 0,
        'stationSlug': 'linefm',
      };
      expect(AlarmRule.tryFromJson(ok), isNotNull);
      expect(
        AlarmRule.tryFromJson(<String, Object?>{...ok, 'hour': 24}),
        isNull,
      );
      expect(
        AlarmRule.tryFromJson(<String, Object?>{...ok, 'hour': -1}),
        isNull,
      );
      expect(
        AlarmRule.tryFromJson(<String, Object?>{...ok, 'minute': 60}),
        isNull,
      );
      expect(
        AlarmRule.tryFromJson(<String, Object?>{...ok, 'hour': '7'}),
        isNull,
      );
      expect(AlarmRule.tryFromJson(<String, Object?>{...ok, 'id': ''}), isNull);
      expect(
        AlarmRule.tryFromJson(<String, Object?>{...ok, 'stationSlug': 3}),
        isNull,
      );
    });

    test('Standardwerte, Begrenzung und Aufraeumen ungueltiger Felder', () {
      final r = AlarmRule.tryFromJson(<String, Object?>{
        'id': 'a',
        'hour': 7,
        'minute': 0,
        'stationSlug': 'linefm',
        'weekdays': <Object?>[1, 9, 'x', 0, 7],
        'volume': 5,
        'enabled': 'ja',
      })!;
      expect(r.weekdays, <int>{1, 7});
      expect(r.volume, 1.0);
      expect(r.enabled, isTrue);
      expect(r.repeats, isTrue);
      final low = AlarmRule.tryFromJson(<String, Object?>{
        'id': 'a',
        'hour': 7,
        'minute': 0,
        'stationSlug': 'linefm',
        'volume': -3,
      })!;
      expect(low.volume, 0.0);
      expect(low.weekdays, isEmpty);
      expect(low.repeats, isFalse);
    });
  });

  group('Clock', () {
    test('SystemClock liefert die aktuelle Zeit', () {
      final before = DateTime.now();
      final now = const SystemClock().now();
      expect(now.isBefore(before), isFalse);
      expect(
        now.difference(DateTime.now()).abs() < const Duration(seconds: 5),
        isTrue,
      );
    });

    test('FakeClock: advance und setTo', () {
      final clock = FakeClock(DateTime(2026));
      clock.advance(const Duration(hours: 1));
      expect(clock.now(), DateTime(2026, 1, 1, 1));
      clock.setTo(DateTime(2027));
      expect(clock.now(), DateTime(2027));
    });
  });
}
