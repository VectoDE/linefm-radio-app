import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/berlin_time.dart';
import 'package:linefm_radio/domain/schedule_slot.dart';

void main() {
  group('BerlinTime', () {
    test('offset follows the EU summer-time rule', () {
      expect(BerlinTime.offsetHoursAtUtc(DateTime.utc(2026, 1, 15, 12)), 1);
      expect(BerlinTime.offsetHoursAtUtc(DateTime.utc(2026, 7, 15, 12)), 2);
      // 2026: switches on 29 March and 25 October at 01:00 UTC.
      expect(BerlinTime.offsetHoursAtUtc(DateTime.utc(2026, 3, 29, 0, 59)), 1);
      expect(BerlinTime.offsetHoursAtUtc(DateTime.utc(2026, 3, 29, 1)), 2);
      expect(BerlinTime.offsetHoursAtUtc(DateTime.utc(2026, 10, 25, 0, 59)), 2);
      expect(BerlinTime.offsetHoursAtUtc(DateTime.utc(2026, 10, 25, 1)), 1);
    });

    test('toUtc converts winter and summer wall-clock times', () {
      expect(BerlinTime.toUtc(2026, 1, 5, 18), DateTime.utc(2026, 1, 5, 17));
      expect(BerlinTime.toUtc(2026, 7, 6, 18), DateTime.utc(2026, 7, 6, 16));
    });

    test('toUtc handles the skipped and the repeated hour', () {
      // 02:00 on 29 March 2026 does not exist; it maps to 03:00 CEST.
      expect(BerlinTime.toUtc(2026, 3, 29, 2), DateTime.utc(2026, 3, 29, 1));
      // 02:00 on 25 October 2026 happens twice; the first one (CEST) wins.
      expect(BerlinTime.toUtc(2026, 10, 25, 2), DateTime.utc(2026, 10, 25, 0));
      expect(BerlinTime.toUtc(2026, 10, 25, 3), DateTime.utc(2026, 10, 25, 2));
    });
  });

  group('ScheduleSlot times', () {
    const wed18 = ScheduleSlot(
      name: 'Show',
      day: ScheduleDay.wed,
      startHour: 18,
      endHour: 20,
    );
    const nightFri = ScheduleSlot(
      name: 'Night',
      day: ScheduleDay.fri,
      startHour: 22,
      endHour: 2,
    );
    const mon0 = ScheduleSlot(name: 'Mon', day: ScheduleDay.mon, startHour: 0);

    test('startInWeekOf uses the Berlin week with Monday as first day', () {
      // Sunday 21:00 UTC is Sunday 23:00 Berlin, still the old week.
      expect(
        wed18.startInWeekOf(DateTime.utc(2026, 7, 12, 21)),
        DateTime.utc(2026, 7, 8, 16),
      );
      // Sunday 23:30 UTC is Monday 01:30 Berlin, already the new week.
      expect(
        wed18.startInWeekOf(DateTime.utc(2026, 7, 12, 23, 30)),
        DateTime.utc(2026, 7, 15, 16),
      );
    });

    test('endFor adds a day when the block runs past midnight', () {
      final start = nightFri.startInWeekOf(DateTime.utc(2026, 7, 8));
      expect(start, DateTime.utc(2026, 7, 10, 20));
      expect(nightFri.endFor(start), DateTime.utc(2026, 7, 11));
      final wedStart = wed18.startInWeekOf(DateTime.utc(2026, 7, 8));
      expect(wed18.endFor(wedStart), DateTime.utc(2026, 7, 8, 18));
    });

    test('endFor is null without an end hour', () {
      final start = mon0.startInWeekOf(DateTime.utc(2026, 7, 8));
      expect(mon0.endFor(start), isNull);
    });

    test(
      'nextStartAfter is strictly after and keeps wall-clock across DST',
      () {
        expect(
          wed18.nextStartAfter(DateTime.utc(2026, 7, 15, 16)),
          DateTime.utc(2026, 7, 22, 16),
        );
        expect(
          wed18.nextStartAfter(DateTime.utc(2026, 7, 15, 15, 59)),
          DateTime.utc(2026, 7, 15, 16),
        );
        // Mon 23 March 00:00 CET is 23:00 UTC; the next Monday 00:00 is CEST.
        expect(
          mon0.nextStartAfter(DateTime.utc(2026, 3, 22, 23)),
          DateTime.utc(2026, 3, 29, 22),
        );
      },
    );
  });
}
