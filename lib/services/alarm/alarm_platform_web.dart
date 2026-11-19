import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/alarm/alarm_inapp.dart';

/// Web: In-App-Timer (nur bei offenem Tab).
AlarmPlatform createAlarmPlatform({required Clock clock}) =>
    InAppAlarmPlatform(clock: clock);

Future<void> initAlarmPlatform() async {}
