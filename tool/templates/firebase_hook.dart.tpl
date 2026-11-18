// GENERIERT von tool/enable_firebase.dart aus tool/templates/firebase_hook.dart.tpl.
// Nicht committen: tool/enable_firebase.dart --disable stellt den Stub wieder her.
import 'package:linefm_firebase/linefm_firebase.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';

/// Firebase-Variante (Analytics + Crashlytics), aktiviert per Skript.
({AnalyticsSink? analytics, CrashSink? crash}) registerFirebase(
  AppConfig config,
) {
  if (!config.firebaseEnabled || !LinefmFirebase.supported) {
    return (analytics: null, crash: null);
  }
  final firebase = LinefmFirebase();
  return (
    analytics: _FirebaseAnalyticsSink(firebase),
    crash: _FirebaseCrashSink(firebase),
  );
}

class _FirebaseAnalyticsSink implements AnalyticsSink {
  _FirebaseAnalyticsSink(this._firebase);

  final LinefmFirebase _firebase;

  @override
  Future<void> init() => _firebase.init();

  @override
  Future<void> screen(String name) => _firebase.logScreen(name);

  @override
  Future<void> event(
    String name, [
    Map<String, Object> props = const {},
  ]) => _firebase.logEvent(name, props);

  @override
  Future<void> setEnabled({required bool enabled}) =>
      _firebase.setEnabled(enabled: enabled);
}

class _FirebaseCrashSink implements CrashSink {
  _FirebaseCrashSink(this._firebase);

  final LinefmFirebase _firebase;

  @override
  Future<void> init() => _firebase.init();

  @override
  Future<void> record(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) => _firebase.recordError(error, stack, fatal: fatal);

  @override
  Future<void> setEnabled({required bool enabled}) =>
      _firebase.setEnabled(enabled: enabled);
}
