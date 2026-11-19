import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
// permission_handler ist bisher nur transitiv eingebunden; P28 nimmt es in
// pubspec.yaml auf (dann entfaellt der ignore).
// ignore: depend_on_referenced_packages
import 'package:permission_handler/permission_handler.dart';

/// Systemfreigaben des Android-Weckers.
///
/// `SCHEDULE_EXACT_ALARM` (Android 12+, ab 14 standardmaessig verweigert) ist
/// die einzige Genauigkeits-Berechtigung der App; `USE_EXACT_ALARM` wird nicht
/// verwendet (Play erlaubt sie nur Wecker-/Kalender-Apps als Kernfunktion,
/// Spec 2.2). Ohne Freigabe plant das Paket `alarm` nur ungenau.
abstract interface class AlarmPermissionGateway {
  /// Darf die App genaue Alarme planen? (vor Android 12 immer ja)
  Future<bool> canScheduleExactAlarms();

  /// Oeffnet die Systemeinstellung "Alarme und Erinnerungen".
  Future<void> openExactAlarmSettings();

  /// Mitteilungen erlauben (Android 13+, fuer die Weck-Benachrichtigung).
  Future<void> requestNotifications();
}

class SystemAlarmPermissionGateway implements AlarmPermissionGateway {
  const SystemAlarmPermissionGateway();

  @override
  Future<bool> canScheduleExactAlarms() =>
      Permission.scheduleExactAlarm.status.isGranted;

  @override
  Future<void> openExactAlarmSettings() async {
    // Auf Android 12+ springt request() direkt in die Systemeinstellung.
    await Permission.scheduleExactAlarm.request();
  }

  @override
  Future<void> requestNotifications() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
}

/// Ist der Wecker auf dieser Plattform voll einsatzfaehig? Nur Android kennt
/// eine fehlende Freigabe; sonst immer `true`.
Future<bool> alarmPermissionCheck(
  AlarmPermissionGateway gateway, {
  bool? isAndroid,
}) async {
  final android =
      isAndroid ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
  if (!android) return true;
  await gateway.requestNotifications();
  return gateway.canScheduleExactAlarms();
}

/// Oeffnet die passende Systemeinstellung (nur Android; sonst keine Aktion).
Future<void> alarmOpenSystemSettings(
  AlarmPermissionGateway gateway, {
  bool? isAndroid,
}) async {
  final android =
      isAndroid ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
  if (!android) return;
  await gateway.openExactAlarmSettings();
}
