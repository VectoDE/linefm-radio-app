/// Optionale Firebase-Anbindung fuer LINEFM Radio.
///
/// Das Paket kennt die App nicht (keine Rueckwaerts-Abhaengigkeit). Die
/// Sinks der App (`AnalyticsSink`/`CrashSink`) entstehen in der Vorlage
/// `tool/templates/firebase_hook.dart.tpl`, die `tool/enable_firebase.dart`
/// nach `lib/services/telemetry/firebase_hook.dart` kopiert.
///
/// Es wird keine `google-services.json` und keine `GoogleService-Info.plist`
/// benoetigt: die Optionen kommen aus `--dart-define` (config/app.json).
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class LinefmFirebase {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _appIdAndroid = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
  );
  static const _appIdIos = String.fromEnvironment('FIREBASE_APP_ID_IOS');
  static const _appIdMacos = String.fromEnvironment('FIREBASE_APP_ID_MACOS');
  static const _appIdWeb = String.fromEnvironment('FIREBASE_APP_ID_WEB');

  bool _ready = false;

  /// Firebase wird nur auf Android, iOS, macOS und Web unterstuetzt.
  static bool get supported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static String get _appId {
    if (kIsWeb) return _appIdWeb;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _appIdAndroid,
      TargetPlatform.iOS => _appIdIos,
      TargetPlatform.macOS => _appIdMacos,
      _ => '',
    };
  }

  /// Gesamte Konfiguration vorhanden?
  static bool get configured =>
      _apiKey.isNotEmpty &&
      _projectId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _appId.isNotEmpty;

  /// Initialisiert Firebase (idempotent). Nur nach Einwilligung aufrufen.
  Future<void> init() async {
    if (_ready || !supported || !configured) return;
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _senderId,
        projectId: _projectId,
      ),
    );
    _ready = true;
  }

  Future<void> setEnabled({required bool enabled}) async {
    if (!_ready) return;
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        enabled,
      );
    }
  }

  Future<void> logScreen(String name) async {
    if (!_ready) return;
    await FirebaseAnalytics.instance.logScreenView(screenName: name);
  }

  Future<void> logEvent(String name, Map<String, Object> props) async {
    if (!_ready) return;
    await FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: props.isEmpty ? null : props,
    );
  }

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    if (!_ready || kIsWeb) return;
    await FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }
}
