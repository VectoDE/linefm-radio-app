import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';

/// Umami ueber POST /api/send (Spec 2.3). Stub ohne Netzwerkaufruf, P07.
class UmamiSink implements AnalyticsSink {
  UmamiSink(this.config);

  final AppConfig config;

  @override
  Future<void> init() async {}

  @override
  Future<void> screen(String name) async {}

  @override
  Future<void> event(
    String name, [
    Map<String, Object> props = const {},
  ]) async {}

  @override
  Future<void> setEnabled({required bool enabled}) async {}
}
