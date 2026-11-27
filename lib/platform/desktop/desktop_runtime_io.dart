// Teile von window_manager (DragToMoveArea) gibt es nur ueber `legacy.dart`.
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:linefm_radio/platform/desktop/desktop_controller.dart';
import 'package:linefm_radio/platform/desktop/hotkeys.dart';
import 'package:linefm_radio/platform/desktop/hotkeys_impl.dart';
import 'package:linefm_radio/platform/desktop/tray_impl.dart';
import 'package:linefm_radio/platform/desktop/window_caption_impl.dart';
import 'package:linefm_radio/platform/desktop/window_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/legacy.dart' show DragToMoveArea;

/// Kanal des Windows-Runners: ein zweiter Programmstart reicht seine
/// Kommandozeile hierher weiter (Single-Instance, `windows/runner/`).
const MethodChannel singleInstanceChannel = MethodChannel(
  'de.linefm.app/single_instance',
);

/// Desktop-Umsetzung von `initDesktop()`: Windows, Linux, macOS.
Future<void> initDesktopRuntime() async {
  if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;
  final desktop = DesktopController.instance;
  try {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } on Object catch (e) {
      debugPrint('Speicher fuer Fensterwerte nicht lesbar: $e');
    }

    final window = WindowManagerDesktopWindow(prefs);
    await window.init(
      closeToTray: WindowManagerDesktopWindow.readCloseToTray(prefs),
    );
    // Systemleiste ist ausgeblendet: die eigene Leiste muss jetzt stehen,
    // sonst liesse sich das Fenster weder ziehen noch schliessen.
    if (window.customTitleBar) {
      var maximized = false;
      try {
        maximized = await window.isMaximized();
      } on Object catch (e) {
        debugPrint('Fensterzustand nicht lesbar: $e');
      }
      desktop.caption = WindowManagerCaptionControls(
        style: WindowManagerCaptionControls.platformStyle(),
        maximized: maximized,
      );
    }
    desktop
      ..window = window
      ..dragArea = ((child) => DragToMoveArea(child: child))
      ..restoreMiniOnTop(value: WindowManagerDesktopWindow.readMiniOnTop(prefs))
      ..active = true;

    final tray = TrayManagerTrayController(desktop);
    desktop
      ..tray = tray
      ..hotkeys = HotkeyManagerDesktopHotkeys(desktop);
    // Tray icon and global hotkeys are not needed for the first frame:
    // start them once it is on screen, so their native setup does not
    // delay the window.
    unawaited(
      WidgetsBinding.instance.waitUntilFirstFrameRasterized.then(
        (_) => _startTrayAndHotkeys(window, tray, desktop.hotkeys),
      ),
    );

    singleInstanceChannel.setMethodCallHandler((call) async {
      if (call.method != 'secondInstance') return;
      final args = (call.arguments as List<Object?>? ?? const <Object?>[])
          .whereType<String>()
          .toList();
      desktop.notifySecondInstance(args);
      // Das Fenster holt der Runner selbst nach vorn; hier nur sicherstellen,
      // dass es nicht im Mini- oder Tray-Zustand haengt.
      await desktop.showWindow();
    });
  } on Object catch (e) {
    // Desktop-Extras sind optional: die App muss auch ohne starten.
    debugPrint('Desktop-Extras nicht gestartet: $e');
  }
}

Future<void> _startTrayAndHotkeys(
  WindowManagerDesktopWindow window,
  TrayManagerTrayController tray,
  DesktopHotkeys hotkeys,
) async {
  try {
    await tray.init();
    // Ohne Tray-Symbol darf Schliessen das Fenster nicht verstecken.
    window.trayAvailable = tray.isAvailable;
    await hotkeys.register();
  } on Object catch (e) {
    debugPrint('Desktop-Extras nicht gestartet: $e');
  }
}
