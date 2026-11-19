import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:linefm_radio/features/alarm/alarm_hooks.dart';

/// Systemfreigaben des Android-Weckers.
///
/// `SCHEDULE_EXACT_ALARM` (Android 12+, ab 14 standardmaessig verweigert) ist
/// die einzige Genauigkeits-Berechtigung der App; `USE_EXACT_ALARM` wird nicht
/// verwendet (Play erlaubt sie nur Wecker-/Kalender-Apps als Kernfunktion,
/// Spec 2.2). `USE_FULL_SCREEN_INTENT` (Android 14+) steht fuer das
/// Vollbild-Wecken; fehlt sie, faellt der Wecker auf eine Benachrichtigung
/// hoher Prioritaet zurueck.
abstract interface class AlarmPermissionGateway {
  /// Darf die App genaue Alarme planen? (vor Android 12 immer ja)
  Future<bool> canScheduleExactAlarms();

  /// Oeffnet die Systemeinstellung "Alarme und Erinnerungen".
  Future<void> openExactAlarmSettings();

  /// Darf die App Vollbild-Benachrichtigungen zeigen? (vor Android 14 ja)
  Future<bool> canUseFullScreenIntent();

  /// Oeffnet die Systemeinstellung "Vollbild-Benachrichtigungen".
  Future<void> openFullScreenIntentSettings();

  /// Mitteilungen erlauben (Android 13+, fuer die Weck-Benachrichtigung).
  Future<void> requestNotifications();

  /// Hat sich seit dem letzten Aufruf Zeitzone oder Uhrzeit geaendert? Liest
  /// und loescht das Merkzeichen des nativen `TimeChangeReceiver`.
  Future<bool> consumeRescheduleFlag();
}

/// Kanal zu `AlarmChannel.kt` (android/app/src/main/kotlin/de/linefm/app).
class SystemAlarmPermissionGateway implements AlarmPermissionGateway {
  const SystemAlarmPermissionGateway();

  static const MethodChannel _channel = MethodChannel(
    'de.linefm.app/alarm_android',
  );

  Future<bool> _bool(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? true;
    } on MissingPluginException {
      return true;
    } on PlatformException catch (e) {
      debugPrint('Wecker-Freigabe $method: $e');
      return true;
    }
  }

  Future<void> _call(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Keine native Seite (Test, Desktop).
    } on PlatformException catch (e) {
      debugPrint('Wecker-Freigabe $method: $e');
    }
  }

  @override
  Future<bool> canScheduleExactAlarms() => _bool('canScheduleExactAlarms');

  @override
  Future<void> openExactAlarmSettings() => _call('openExactAlarmSettings');

  @override
  Future<bool> canUseFullScreenIntent() => _bool('canUseFullScreenIntent');

  @override
  Future<void> openFullScreenIntentSettings() =>
      _call('openFullScreenIntentSettings');

  @override
  Future<void> requestNotifications() => _call('requestNotifications');

  @override
  Future<bool> consumeRescheduleFlag() async {
    try {
      return await _channel.invokeMethod<bool>('consumeRescheduleFlag') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('Wecker-Merkzeichen: $e');
      return false;
    }
  }
}

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Ist der Wecker auf dieser Plattform voll einsatzfaehig? Nur Android kennt
/// eine fehlende Freigabe; sonst immer `true`. Fragt zusaetzlich nach der
/// Mitteilungs-Erlaubnis.
Future<bool> alarmPermissionCheck(
  AlarmPermissionGateway gateway, {
  bool? isAndroid,
}) async {
  if (!(isAndroid ?? _isAndroid)) return true;
  await gateway.requestNotifications();
  return gateway.canScheduleExactAlarms();
}

/// Oeffnet die Systemeinstellung fuer genaue Alarme (nur Android).
Future<void> alarmOpenSystemSettings(
  AlarmPermissionGateway gateway, {
  bool? isAndroid,
}) async {
  if (!(isAndroid ?? _isAndroid)) return;
  await gateway.openExactAlarmSettings();
}

/// Stiller Stand beider Freigaben (ohne Rueckfrage), fuer den dauerhaften
/// Hinweis im Wecker-Screen.
Future<AlarmPermissionStatus> alarmPermissionStatus(
  AlarmPermissionGateway gateway, {
  bool? isAndroid,
}) async {
  if (!(isAndroid ?? _isAndroid)) return const AlarmPermissionStatus();
  return AlarmPermissionStatus(
    exactOk: await gateway.canScheduleExactAlarms(),
    fullScreenOk: await gateway.canUseFullScreenIntent(),
  );
}

/// Zeitzone/Uhrzeit seit dem letzten Mal geaendert (nur Android).
Future<bool> alarmConsumeRescheduleFlag(
  AlarmPermissionGateway gateway, {
  bool? isAndroid,
}) async {
  if (!(isAndroid ?? _isAndroid)) return false;
  return gateway.consumeRescheduleFlag();
}

/// Oeffnet die Systemeinstellung fuer Vollbild-Benachrichtigungen (Android).
Future<void> alarmOpenFullScreenSettings(
  AlarmPermissionGateway gateway, {
  bool? isAndroid,
}) async {
  if (!(isAndroid ?? _isAndroid)) return;
  await gateway.openFullScreenIntentSettings();
}
