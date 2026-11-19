/// Fensterverhalten (Spec 2.2): Titel, Groesse/Position merken, Mini-Fenster,
/// immer im Vordergrund, Schliessen in den Tray. Die Umsetzung mit
/// window_manager liegt in `window_impl.dart` (nur Desktop); dieses Interface
/// ist plattformneutral, damit Web und Mobil es ohne native Pakete kennen.
abstract interface class DesktopWindow {
  Future<void> show();

  Future<void> hide();

  Future<void> setAlwaysOnTop({required bool value});

  /// Wechselt in das Mini-Fenster (360x120, rahmenlos).
  Future<void> enterMini({required bool alwaysOnTop});

  /// Zurueck zur gemerkten Groesse und Position des normalen Fensters.
  Future<void> exitMini({required bool alwaysOnTop});

  /// Ohne Tray-Symbol darf das Fenster nicht verschwinden; dann bleibt
  /// Schliessen-in-Tray aus, egal was die Einstellung sagt.
  set trayAvailable(bool value);

  /// true: Schliessen blendet das Fenster aus, die App laeuft im Tray weiter.
  Future<void> setCloseToTray({required bool value});

  /// Beendet die App endgueltig, auch bei aktivem Schliessen-in-Tray.
  Future<void> quit();
}

class NoopDesktopWindow implements DesktopWindow {
  const NoopDesktopWindow();

  @override
  set trayAvailable(bool value) {}

  @override
  Future<void> show() async {}

  @override
  Future<void> hide() async {}

  @override
  Future<void> setAlwaysOnTop({required bool value}) async {}

  @override
  Future<void> enterMini({required bool alwaysOnTop}) async {}

  @override
  Future<void> exitMini({required bool alwaysOnTop}) async {}

  @override
  Future<void> setCloseToTray({required bool value}) async {}

  @override
  Future<void> quit() async {}
}
