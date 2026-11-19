/// Globale Tastenkuerzel (Spec 2.2). Die Umsetzung mit hotkey_manager liegt
/// in `hotkeys_impl.dart` (nur Desktop).
///
/// Standard (Strg bzw. Cmd + Alt): P = Play/Stop, Pfeil rechts/links =
/// naechster/vorheriger Sender, Pfeil hoch/runter = Lautstaerke, M =
/// Mini-Player. Medientasten behandelt das System (SMTC unter Windows, MPRIS
/// unter Linux, MediaRemote unter macOS); nur wenn die Windows-SMTC-Bruecke
/// nicht laeuft, uebernehmen sie als globale Kuerzel.
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
