import 'package:linefm_radio/domain/alarm/alarm_rule.dart';

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
