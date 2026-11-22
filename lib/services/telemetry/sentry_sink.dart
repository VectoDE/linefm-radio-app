import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

typedef SentryInitFn = Future<void> Function(
  FlutterOptionsConfiguration configuration,
);
typedef SentryCaptureFn = Future<void> Function(Object error, StackTrace stack);
typedef SentryCloseFn = Future<void> Function();

/// GlitchTip oder Sentry ueber sentry_flutter (Spec 2.3, gleiches Protokoll,
/// ein DSN).
///
/// Das SDK wird erst nach Einwilligung gestartet (`setEnabled(true)`) und
/// bei Widerruf wieder beendet. Ohne Einwilligung passiert nichts.
class SentrySink implements CrashSink {
  SentrySink(
    this.config, {
    SentryInitFn? initSdk,
    SentryCaptureFn? capture,
    SentryCloseFn? close,
  }) : _initSdk = initSdk ?? SentryFlutter.init,
       _capture = capture ?? _defaultCapture,
       _close = close ?? Sentry.close;

  final AppConfig config;
  final SentryInitFn _initSdk;
  final SentryCaptureFn _capture;
  final SentryCloseFn _close;

  bool _enabled = false;
  bool _sdkReady = false;

  static Future<void> _defaultCapture(Object error, StackTrace stack) async {
    await Sentry.captureException(error, stackTrace: stack);
  }

  /// Startet das SDK. Wird nur nach Einwilligung aufgerufen; idempotent.
  @override
  Future<void> init() async {
    if (_sdkReady) return;
    await _initSdk(configureOptions);
    _sdkReady = true;
  }

  /// Datenschutz-Optionen (oeffentlich fuer Tests).
  void configureOptions(SentryFlutterOptions options) {
    options
      ..dsn = config.sentryDsn
      ..environment = config.sentryEnvironment.isNotEmpty
          ? config.sentryEnvironment
          : config.appEnv
      ..release = 'linefm-radio@${config.versionLabel}'
      ..sendDefaultPii = false
      ..tracesSampleRate = 0
      ..attachScreenshot = false
      ..attachViewHierarchy = false
      ..reportPackages = false
      ..enableUserInteractionBreadcrumbs = false
      ..beforeSend = scrubEvent;
  }

  /// Entfernt Geraetename, Server-Name und IP/Nutzerangaben.
  static FutureOr<SentryEvent?> scrubEvent(SentryEvent event, Hint hint) {
    event
      ..serverName = null
      ..user = null;
    event.contexts.device?.name = null;
    return event;
  }

  @override
  Future<void> setEnabled({required bool enabled}) async {
    if (enabled == _enabled) return;
    _enabled = enabled;
    if (enabled) {
      await init();
    } else if (_sdkReady) {
      _sdkReady = false;
      await _close();
    }
  }

  @override
  Future<void> record(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    if (!_enabled || !_sdkReady) {
      debugPrint('Fehler (lokal, keine Einwilligung): $error');
      return;
    }
    await _capture(error, stack);
  }
}
