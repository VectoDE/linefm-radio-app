import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/alarm/alarm_schedule.dart';

import '../support/test_doubles.dart';

/// Die Zeitumstellungs-Tests mit festen Uhrzeiten gelten fuer Zeitzonen mit
/// EU-Regel (Europe/Berlin). In anderen Zeitzonen (z. B. UTC in der CI) laufen
/// stattdessen die zonenunabhaengigen Eigenschaftstests weiter unten.
final bool isEuropeanZone =
    DateTime(2027, 3, 27, 12).timeZoneOffset == const Duration(hours: 1) &&
    DateTime(2027, 3, 28, 12).timeZoneOffset == const Duration(hours: 2) &&
    DateTime(2026, 10, 24, 12).timeZoneOffset == const Duration(hours: 2) &&
    DateTime(2026, 10, 25, 12).timeZoneOffset == const Duration(hours: 1);

AlarmRule rule({
  int hour = 7,
  int minute = 0,
  Set<int> weekdays = const <int>{},
  bool enabled = true,
}) => AlarmRule(
  id: 'r1',
  hour: hour,
  minute: minute,
  stationSlug: 'linefm',
  weekdays: weekdays,
  enabled: enabled,
);

void main() {
  // 18.11.2026 ist ein Mittwoch.
  final wed = DateTime(2026, 11, 18, 12);

  test('Testdatum ist ein Mittwoch', () {
    expect(wed.weekday, DateTime.wednesday);
  });

  group('einmalig (ohne Wochentage)', () {
    test('heute, wenn die Uhrzeit noch bevorsteht', () {
      expect(
        AlarmSchedule.nextOccurrence(rule(hour: 18), wed),
        DateTime(2026, 11, 18, 18),
      );
    });

    test('morgen, wenn die Uhrzeit vorbei ist', () {
      expect(
        AlarmSchedule.nextOccurrence(rule(hour: 7), wed),
        DateTime(2026, 11, 19, 7),
      );
    });

    test('exakt jetzt zaehlt als vorbei (strikt nach now)', () {
      expect(
        AlarmSchedule.nextOccurrence(rule(hour: 12), wed),
        DateTime(2026, 11, 19, 12),
      );
      expect(
        AlarmSchedule.nextOccurrence(
          rule(hour: 12),
          wed.subtract(const Duration(seconds: 1)),
        ),
        wed,
      );
    });

    test('deaktiviert ergibt null', () {
      expect(AlarmSchedule.nextOccurrence(rule(enabled: false), wed), isNull);
    });
  });

  group('Wochentage', () {
    test('Montag bis Freitag: Freitagabend springt auf Montag', () {
      final fri = DateTime(2026, 11, 20, 20);
      expect(fri.weekday, DateTime.friday);
      final next = AlarmSchedule.nextOccurrence(
        rule(weekdays: <int>{1, 2, 3, 4, 5}),
        fri,
      )!;
      expect(next, DateTime(2026, 11, 23, 7));
      expect(next.weekday, DateTime.monday);
    });

    test('Mittwoch-Regel am Mittwoch nach der Uhrzeit: in 7 Tagen', () {
      expect(
        AlarmSchedule.nextOccurrence(rule(weekdays: <int>{3}), wed),
        DateTime(2026, 11, 25, 7),
      );
    });

    test('Mittwoch-Regel am Mittwoch vor der Uhrzeit: heute', () {
      expect(
        AlarmSchedule.nextOccurrence(rule(hour: 18, weekdays: <int>{3}), wed),
        DateTime(2026, 11, 18, 18),
      );
    });

    test('Sonntag (7) und Wochenende', () {
      final next = AlarmSchedule.nextOccurrence(
        rule(weekdays: <int>{6, 7}),
        wed,
      )!;
      expect(next, DateTime(2026, 11, 21, 7));
      expect(next.weekday, DateTime.saturday);
      expect(
        AlarmSchedule.nextOccurrence(rule(weekdays: <int>{7}), wed)!.weekday,
        DateTime.sunday,
      );
    });

    test('Wochentage ausserhalb 1..7 treffen nie', () {
      expect(
        AlarmSchedule.nextOccurrence(rule(weekdays: <int>{0, 8}), wed),
        isNull,
      );
    });
  });

  group('Mitternacht und Kalendergrenzen', () {
    test('00:00 von 23:59 aus: naechster Tag', () {
      expect(
        AlarmSchedule.nextOccurrence(
          rule(hour: 0, minute: 0),
          DateTime(2026, 11, 18, 23, 59),
        ),
        DateTime(2026, 11, 19),
      );
    });

    test('00:00 exakt um 00:00: erst am Folgetag', () {
      expect(
        AlarmSchedule.nextOccurrence(rule(hour: 0), DateTime(2026, 11, 19)),
        DateTime(2026, 11, 20),
      );
    });

    test('23:59-Wecker um 23:58', () {
      expect(
        AlarmSchedule.nextOccurrence(
          rule(hour: 23, minute: 59),
          DateTime(2026, 11, 18, 23, 58),
        ),
        DateTime(2026, 11, 18, 23, 59),
      );
    });

    test('Jahres- und Monatswechsel', () {
      expect(
        AlarmSchedule.nextOccurrence(rule(), DateTime(2026, 12, 31, 23)),
        DateTime(2027, 1, 1, 7),
      );
      expect(
        AlarmSchedule.nextOccurrence(rule(), DateTime(2027, 2, 28, 8)),
        DateTime(2027, 3, 1, 7),
      );
      expect(
        AlarmSchedule.nextOccurrence(rule(), DateTime(2028, 2, 28, 8)),
        DateTime(2028, 2, 29, 7),
      );
    });
  });

  group('Zeitumstellung (zonenunabhaengige Eigenschaften)', () {
    test(
      'taeglich 07:00 trifft rund um beide Umstellungen immer 07:00 Ortszeit',
      () {
        final starts = <DateTime>[
          for (var d = 20; d <= 31; d++) DateTime(2027, 3, d, 12),
          for (var d = 1; d <= 5; d++) DateTime(2027, 4, d, 12),
          for (var d = 20; d <= 31; d++) DateTime(2027, 10, d, 12),
          for (var d = 1; d <= 5; d++) DateTime(2027, 11, d, 12),
        ];
        for (final from in starts) {
          final next = AlarmSchedule.nextOccurrence(rule(), from)!;
          expect(next.hour, 7, reason: 'ab $from');
          expect(next.minute, 0, reason: 'ab $from');
          expect(next.isAfter(from), isTrue);
          final gap = next.difference(from);
          // 19 h bis zum naechsten 07:00, +/- 1 h Zeitumstellung.
          expect(gap, greaterThanOrEqualTo(const Duration(hours: 18)));
          expect(gap, lessThanOrEqualTo(const Duration(hours: 20)));
        }
      },
    );

    test('Wochen-Wecker bleibt ueber die Umstellung auf der Uhrzeit', () {
      var cursor = DateTime(2027, 3, 1);
      final r = rule(hour: 6, minute: 45, weekdays: <int>{1});
      for (var i = 0; i < 6; i++) {
        final next = AlarmSchedule.nextOccurrence(r, cursor)!;
        expect(next.weekday, DateTime.monday);
        expect(next.hour, 6);
        expect(next.minute, 45);
        cursor = next;
      }
    });
  });

  group(
    'Zeitumstellung Europe/Berlin',
    skip: isEuropeanZone ? false : 'Zeitzone des Rechners hat keine EU-Regel',
    () {
      test('Maerz: 07:00 liegt 22 Stunden nach 08:00 am Vortag', () {
        final next = AlarmSchedule.nextOccurrence(
          rule(),
          DateTime(2027, 3, 27, 8),
        )!;
        expect(next, DateTime(2027, 3, 28, 7));
        expect(
          next.difference(DateTime(2027, 3, 27, 8)),
          const Duration(hours: 22),
        );
      });

      test('Oktober: 07:00 liegt 24 Stunden nach 08:00 am Vortag', () {
        final next = AlarmSchedule.nextOccurrence(
          rule(),
          DateTime(2026, 10, 24, 8),
        )!;
        expect(next, DateTime(2026, 10, 25, 7));
        expect(
          next.difference(DateTime(2026, 10, 24, 8)),
          const Duration(hours: 24),
        );
      });

      test('Maerz: 02:30 existiert nicht und klingelt um 03:30', () {
        final next = AlarmSchedule.nextOccurrence(
          rule(hour: 2, minute: 30),
          DateTime(2027, 3, 27, 23),
        )!;
        expect(next.day, 28);
        expect(next.hour, 3);
        expect(next.minute, 30);
      });

      test('Maerz: Wecker am Folgetag liegt wieder auf 02:30', () {
        final next = AlarmSchedule.nextOccurrence(
          rule(hour: 2, minute: 30),
          DateTime(2027, 3, 28, 12),
        )!;
        expect(next, DateTime(2027, 3, 29, 2, 30));
      });

      test('Oktober: 02:30 in der doppelten Stunde klingelt genau einmal', () {
        var cursor = DateTime(2026, 10, 24, 23);
        final r = rule(hour: 2, minute: 30);
        final first = AlarmSchedule.nextOccurrence(r, cursor)!;
        expect(first.day, 25);
        expect(first.hour, 2);
        cursor = first;
        final second = AlarmSchedule.nextOccurrence(r, cursor)!;
        expect(second.day, 26);
        expect(second.hour, 2);
      });
    },
  );

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
    final r = rule(hour: 7);

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
