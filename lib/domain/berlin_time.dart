/// Wall-clock arithmetic for Europe/Berlin without a timezone package.
///
/// laut.fm publishes schedule times as Berlin wall-clock hours. The EU rule is
/// fixed: summer time (UTC+2) runs from the last Sunday of March 01:00 UTC to
/// the last Sunday of October 01:00 UTC, otherwise UTC+1.
class BerlinTime {
  const BerlinTime._();

  static int _lastSunday(int year, int month) {
    final last = DateTime.utc(year, month + 1, 0);
    return last.day - (last.weekday % 7);
  }

  /// UTC offset in hours for the given instant.
  static int offsetHoursAtUtc(DateTime instant) {
    final u = instant.toUtc();
    final start = DateTime.utc(u.year, 3, _lastSunday(u.year, 3), 1);
    final end = DateTime.utc(u.year, 10, _lastSunday(u.year, 10), 1);
    return !u.isBefore(start) && u.isBefore(end) ? 2 : 1;
  }

  /// Berlin wall-clock fields of [instant], carried in a UTC-flagged
  /// [DateTime] (the fields hold Berlin local values; the flag is only a
  /// carrier and the result is not an instant).
  static DateTime wallClock(DateTime instant) {
    final u = instant.toUtc();
    return u.add(Duration(hours: offsetHoursAtUtc(u)));
  }

  /// UTC instant for a Berlin wall-clock time. A time in the skipped hour
  /// (spring forward) maps to the instant one hour later; in the repeated hour
  /// (fall back) the first occurrence wins. Day overflow is normalised.
  static DateTime toUtc(int year, int month, int day, int hour) {
    final naive = DateTime.utc(year, month, day, hour);
    final asSummer = naive.subtract(const Duration(hours: 2));
    if (offsetHoursAtUtc(asSummer) == 2) return asSummer;
    return naive.subtract(const Duration(hours: 1));
  }
}
