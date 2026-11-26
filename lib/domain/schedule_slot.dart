import 'package:linefm_radio/domain/berlin_time.dart';

/// Weekday of a schedule entry (laut.fm: `mon` to `sun`).
enum ScheduleDay {
  mon,
  tue,
  wed,
  thu,
  fri,
  sat,
  sun;

  /// Matches [DateTime.weekday] (Monday = 1 ... Sunday = 7).
  int get weekday => index + 1;

  static ScheduleDay? tryParse(Object? value) {
    if (value is! String) return null;
    final key = value.trim().toLowerCase();
    for (final day in values) {
      if (day.name == key) return day;
    }
    return null;
  }
}

/// One block of the laut.fm schedule (`GET /station/{slug}/schedule`).
///
/// Times are Europe/Berlin wall-clock hours. [startHour] is 0 to 23.
/// [endHour] is the hour the block ends (1 to 24); `null` if laut.fm sends no
/// end (the block then lasts until the next entry, or all day on 24/7
/// stations). An [endHour] less than or equal to [startHour] means the block
/// runs past midnight.
class ScheduleSlot {
  const ScheduleSlot({
    required this.name,
    required this.day,
    required this.startHour,
    this.id,
    this.endHour,
    this.description,
    this.colorHex,
    this.shuffled,
  });

  final int? id;
  final String name;
  final ScheduleDay day;
  final int startHour;
  final int? endHour;
  final String? description;

  /// Colour as `#rrggbb`, as delivered by laut.fm.
  final String? colorHex;
  final bool? shuffled;

  /// Start of the occurrence in the Berlin week (Monday first) containing
  /// [reference], as a UTC instant.
  DateTime startInWeekOf(DateTime reference) {
    final wall = BerlinTime.wallClock(reference);
    return BerlinTime.toUtc(
      wall.year,
      wall.month,
      wall.day - (wall.weekday - 1) + day.index,
      startHour,
    );
  }

  /// End of the occurrence starting at [start] (a UTC instant from
  /// [startInWeekOf]); `null` when [endHour] is unknown.
  DateTime? endFor(DateTime start) {
    final end = endHour;
    if (end == null) return null;
    final wall = BerlinTime.wallClock(start);
    final extraDays = end <= startHour ? 1 : 0;
    return BerlinTime.toUtc(wall.year, wall.month, wall.day + extraDays, end);
  }

  /// Next start strictly after [after], as a UTC instant.
  DateTime nextStartAfter(DateTime after) {
    final base = startInWeekOf(after);
    if (base.isAfter(after)) return base;
    final wall = BerlinTime.wallClock(base);
    return BerlinTime.toUtc(wall.year, wall.month, wall.day + 7, startHour);
  }
}
