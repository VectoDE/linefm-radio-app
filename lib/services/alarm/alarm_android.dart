import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';

/// Android: Paket alarm (setAlarmClock). Stub, P20.
class AndroidAlarmPlatform implements AlarmPlatform {
  const AndroidAlarmPlatform();

  @override
  Future<void> init() async {}

  @override
  Future<void> schedule(AlarmRule rule) async {
    throw UnimplementedError('P20: AndroidAlarmPlatform.schedule');
  }

  @override
  Future<void> cancel(String ruleId) async {
    throw UnimplementedError('P20: AndroidAlarmPlatform.cancel');
  }
}
