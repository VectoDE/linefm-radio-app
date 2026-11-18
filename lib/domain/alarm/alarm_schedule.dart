import 'package:linefm_radio/domain/alarm/alarm_rule.dart';

/// Terminberechnung fuer Wecker (Stub, P02).
class AlarmSchedule {
  const AlarmSchedule._();

  static const Duration snooze = Duration(minutes: 9);

  static DateTime? nextOccurrence(AlarmRule rule, DateTime now) {
    throw UnimplementedError('P02: AlarmSchedule.nextOccurrence');
  }
}
