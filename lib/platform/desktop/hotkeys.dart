/// Globale Tastenkuerzel (Spec 2.2). Stub, P18.
abstract interface class DesktopHotkeys {
  Future<void> register();

  Future<void> unregisterAll();
}

class NoopDesktopHotkeys implements DesktopHotkeys {
  const NoopDesktopHotkeys();

  @override
  Future<void> register() async {}

  @override
  Future<void> unregisterAll() async {}
}
