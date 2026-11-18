/// Fensterverhalten: Titel, Position merken, immer im Vordergrund,
/// Schliessen in den Tray. Stub, P18.
abstract interface class DesktopWindow {
  Future<void> show();

  Future<void> hide();

  Future<void> setAlwaysOnTop({required bool value});
}

class NoopDesktopWindow implements DesktopWindow {
  const NoopDesktopWindow();

  @override
  Future<void> show() async {}

  @override
  Future<void> hide() async {}

  @override
  Future<void> setAlwaysOnTop({required bool value}) async {}
}
