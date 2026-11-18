/// Schnittstellen fuer Statistik und Absturzberichte (Spec 2.3).
abstract interface class AnalyticsSink {
  Future<void> init();
  Future<void> screen(String name);
  Future<void> event(String name, [Map<String, Object> props = const {}]);
  Future<void> setEnabled({required bool enabled});
}

abstract interface class CrashSink {
  /// Erst nach Einwilligung aufrufen.
  Future<void> init();
  Future<void> record(Object error, StackTrace stack, {bool fatal = false});
  Future<void> setEnabled({required bool enabled});
}
