import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform;
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/services/alarm/alarm_android.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/alarm/alarm_inapp.dart';
import 'package:linefm_radio/services/alarm/alarm_ios.dart';

/// Android: Paket `alarm`; iOS: lokale Mitteilung; Desktop: In-App-Timer.
AlarmPlatform createAlarmPlatform({required Clock clock}) =>
    switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidAlarmPlatform(clock: clock),
      TargetPlatform.iOS => IosAlarmPlatform(),
      _ => InAppAlarmPlatform(clock: clock),
    };

/// Android: Paket `alarm` starten (plant gespeicherte Alarme neu und meldet
/// bereits klingelnde). Sonst nichts.
Future<void> initAlarmPlatform() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await Alarm.init();
  } on Object catch (e) {
    debugPrint('Wecker: Alarm.init fehlgeschlagen: $e');
  }
}
