import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/services/telemetry/firebase_hook.dart';
import 'package:linefm_radio/services/telemetry/sentry_sink.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';
import 'package:linefm_radio/services/telemetry/umami_sink.dart';

/// Verteilt Ereignisse an alle aktiven Sinks und prueft die Einwilligung.
/// Ist nichts konfiguriert oder nicht eingewilligt, passiert nichts.
///
/// Sinks werden erst bei der ersten Einwilligung initialisiert; vorher gibt
/// es keinen Netzwerkaufruf an Telemetrie-Hosts. Fehler in Sinks werden
/// geschluckt, Telemetrie darf die App nie stoeren.
class TelemetryHub {
  TelemetryHub({
    required this.config,
    this.analytics = const <AnalyticsSink>[],
    this.crash = const <CrashSink>[],
    bool consent = false,
    // ignore: prefer_initializing_formals
  }) : _consent = consent;

  /// Hub ohne Wirkung (nichts konfiguriert).
  factory TelemetryHub.noop(AppConfig config) => TelemetryHub(config: config);

  final AppConfig config;
  final List<AnalyticsSink> analytics;
  final List<CrashSink> crash;
  bool _consent;

  /// Sendet nur, wenn etwas konfiguriert ist UND eingewilligt wurde.
  bool get active => config.telemetryConfigured && _consent;

  /// Nur wenn true, darf der Einwilligungsdialog erscheinen.
  bool get consentRequired => config.telemetryConfigured;

  Future<void> setConsent({required bool value}) async {
    _consent = value;
    final enable = active;
    for (final s in analytics) {
      await _guard(() async {
        if (enable) await s.init();
        await s.setEnabled(enabled: enable);
      });
    }
    for (final s in crash) {
      await _guard(() async {
        if (enable) await s.init();
        await s.setEnabled(enabled: enable);
      });
    }
  }

  Future<void> screen(String name) async {
    if (!active) return;
    for (final s in analytics) {
      await _guard(() => s.screen(name));
    }
  }

  Future<void> event(
    String name, [
    Map<String, Object> props = const {},
  ]) async {
    if (!active) return;
    for (final s in analytics) {
      await _guard(() => s.event(name, props));
    }
  }

  Future<void> record(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    if (!active) {
      // Ohne Einwilligung nur lokal loggen (Spec 2.3).
      debugPrint('Fehler (lokal): $error\n$stack');
      return;
    }
    for (final s in crash) {
      await _guard(() => s.record(error, stack, fatal: fatal));
    }
  }

  /// Bindet Flutter- und Plattform-Fehler an [record]. Aufruf in main.dart
  /// (Integration P28), nachdem der Hub existiert.
  void installCrashHandlers() {
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutter?.call(details);
      unawaited(record(details.exception, details.stack ?? StackTrace.empty));
    };
    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(record(error, stack, fatal: true));
      return previousPlatform?.call(error, stack) ?? true;
    };
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      debugPrint('Telemetrie-Sink-Fehler: $e');
    }
  }
}

/// Baut den Hub aus der Konfiguration. Es werden nur Sinks erzeugt, deren
/// Anbieter konfiguriert ist. Ohne Konfiguration: NoOp-Hub. Die gespeicherte
/// Einwilligung wird uebernommen; ohne Einwilligung bleibt alles inaktiv.
Future<TelemetryHub> initTelemetry({
  required AppConfig config,
  required PrefsStore prefs,
  http.Client? client,
  ({AnalyticsSink? analytics, CrashSink? crash}) Function(AppConfig config)
      firebase =
      registerFirebase,
}) async {
  if (!config.telemetryConfigured) return TelemetryHub.noop(config);

  final analytics = <AnalyticsSink>[];
  final crash = <CrashSink>[];
  if (config.umamiConfigured) {
    analytics.add(UmamiSink(config, client: client));
  }
  if (config.sentryConfigured) crash.add(SentrySink(config));
  if (config.firebaseConfigured) {
    final fb = firebase(config);
    if (fb.analytics != null) analytics.add(fb.analytics!);
    if (fb.crash != null) crash.add(fb.crash!);
  }

  final hub = TelemetryHub(config: config, analytics: analytics, crash: crash);
  if (prefs.readTelemetryConsent() ?? false) {
    await hub.setConsent(value: true);
    await hub.event('app_start');
  }
  return hub;
}
