import 'package:linefm_radio/services/telemetry/telemetry.dart';

class NoopAnalyticsSink implements AnalyticsSink {
  const NoopAnalyticsSink();

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

class NoopCrashSink implements CrashSink {
  const NoopCrashSink();

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
