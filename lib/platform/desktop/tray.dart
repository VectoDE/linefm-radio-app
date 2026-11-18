/// Tray-Symbol und -Menue (Spec 2.2). Stub, P18.
abstract interface class TrayController {
  Future<void> init();

  Future<void> setTooltip(String text);

  Future<void> dispose();
}

class NoopTrayController implements TrayController {
  const NoopTrayController();

  @override
  Future<void> init() async {}

  @override
  Future<void> setTooltip(String text) async {}

  @override
  Future<void> dispose() async {}
}
