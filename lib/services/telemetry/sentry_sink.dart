import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';

/// GlitchTip oder Sentry ueber sentry_flutter (Spec 2.3). Stub ohne
/// SDK-Initialisierung, P07.
class SentrySink implements CrashSink {
  SentrySink(this.config);

  final AppConfig config;

  @override
  Future<void> init() async {}

  @override
  Future<void> record(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {}

  @override
  Future<void> setEnabled({required bool enabled}) async {}
}
