import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';

/// iOS: MethodChannel de.linefm.app/alarm_ios (UNCalendarNotificationTrigger).
/// Besitzer: P17.
class IosAlarmPlatform implements AlarmPlatform {
  const IosAlarmPlatform();

  static const String channelName = 'de.linefm.app/alarm_ios';

  @override
  Future<void> init() async {}

  @override
  Future<void> schedule(AlarmRule rule) async {
    throw UnimplementedError('P17: IosAlarmPlatform.schedule');
  }

  @override
  Future<void> cancel(String ruleId) async {
    throw UnimplementedError('P17: IosAlarmPlatform.cancel');
  }
}
