import 'package:linefm_radio/platform/desktop/desktop_runtime_io.dart'
    if (dart.library.js_interop) 'package:linefm_radio/platform/desktop/desktop_runtime_stub.dart';

/// Initialisiert Fenster, Tray und Tastenkuerzel (window_manager,
/// tray_manager, hotkey_manager). No-Op auf Mobil und Web. Besitzer: P18.
///
/// Laeuft vor `runApp`: Titel, gemerkte Groesse/Position und Mindestgroesse
/// stehen, bevor das Fenster mit dem ersten Frame erscheint. Die
/// Wiedergabe-Aktionen bindet danach `DesktopHost` (siehe dort).
Future<void> initDesktop() => initDesktopRuntime();
