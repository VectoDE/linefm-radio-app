import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';

/// Desktop und Web: In-App-Timer gegen die Wanduhr (Pruefung alle 15 s).
/// Stub, P20.
class InAppAlarmPlatform implements AlarmPlatform {
  const InAppAlarmPlatform();

  @override
  Future<void> init() async {}

  @override
  Future<void> schedule(AlarmRule rule) async {
    throw UnimplementedError('P20: InAppAlarmPlatform.schedule');
  }

  @override
  Future<void> cancel(String ruleId) async {
    throw UnimplementedError('P20: InAppAlarmPlatform.cancel');
  }
}
