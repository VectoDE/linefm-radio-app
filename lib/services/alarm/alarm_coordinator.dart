import 'package:linefm_radio/domain/alarm/alarm_rule.dart';

/// Plattformabhaengige Wecker-Ausfuehrung (alarm_android, alarm_ios,
/// alarm_inapp). Implementierung: P20 (iOS-Kanal: P17).
abstract interface class AlarmPlatform {
  Future<void> init();

  Future<void> schedule(AlarmRule rule);

  Future<void> cancel(String ruleId);
}

/// Koordiniert Regeln, Plattform und Sendestart. Stub bis P20.
abstract interface class AlarmCoordinator {
  Future<void> rescheduleAll(List<AlarmRule> rules);

  Future<void> snooze(String ruleId);

  Future<void> dismiss(String ruleId);
}

class NoopAlarmCoordinator implements AlarmCoordinator {
  const NoopAlarmCoordinator();

  @override
  Future<void> rescheduleAll(List<AlarmRule> rules) async {}

  @override
  Future<void> snooze(String ruleId) async {}

  @override
  Future<void> dismiss(String ruleId) async {}
}

/// Initialisiert den Wecker (No-Op bis P20).
Future<void> initAlarm() async {}
