import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';

/// Verteilt Ereignisse an alle aktiven Sinks und prueft die Einwilligung.
/// Ist nichts konfiguriert oder nicht eingewilligt, passiert nichts.
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

  bool get active => config.telemetryConfigured && _consent;

  Future<void> setConsent({required bool value}) async {
    _consent = value;
    for (final s in analytics) {
      await s.setEnabled(enabled: active);
    }
    for (final s in crash) {
      await s.setEnabled(enabled: active);
    }
  }

  Future<void> screen(String name) async {
    if (!active) return;
    for (final s in analytics) {
      await s.screen(name);
    }
  }

  Future<void> event(
    String name, [
    Map<String, Object> props = const {},
  ]) async {
    if (!active) return;
    for (final s in analytics) {
      await s.event(name, props);
    }
  }

  Future<void> record(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    if (!active) return;
    for (final s in crash) {
      await s.record(error, stack, fatal: fatal);
    }
  }
}

/// Baut den Hub. Stub: NoOp-Hub, die Sinks verdrahtet P07.
Future<TelemetryHub> initTelemetry({
  required AppConfig config,
  required PrefsStore prefs,
}) async => TelemetryHub.noop(config);
