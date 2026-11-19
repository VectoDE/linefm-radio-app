/// Tray-Symbol und -Menue (Spec 2.2). Die Umsetzung mit tray_manager liegt
/// in `tray_impl.dart` (nur Desktop).
abstract interface class TrayController {
  /// Legt das Symbol an. Danach zeigt [isAvailable], ob das System eines
  /// anzeigt (GNOME ohne AppIndicator: nein).
  Future<void> init();

  bool get isAvailable;

  Future<void> setTooltip(String text);

  /// Baut das Menue neu auf (Titel, Play/Stop, aktiver Sender, Haken).
  Future<void> refresh();

  Future<void> dispose();
}

class NoopTrayController implements TrayController {
  const NoopTrayController();

  @override
  Future<void> init() async {}

  @override
  bool get isAvailable => false;

  @override
  Future<void> setTooltip(String text) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> dispose() async {}
}
