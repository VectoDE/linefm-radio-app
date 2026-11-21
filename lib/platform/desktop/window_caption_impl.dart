// Die Zustandsereignisse (Fokus, Maximieren, Vollbild) liefert in
// window_manager 0.7 nur die als veraltet markierte `legacy.dart`, auf der
// auch `window_impl.dart` aufsetzt.
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:linefm_radio/platform/desktop/window_caption.dart';
import 'package:window_manager/legacy.dart'
    show DragToMoveArea, DragToResizeArea, WindowListener, WindowManager;
import 'package:window_manager/window_manager.dart' show MaximizeButtonArea;

/// Breite der Griffe zur Groessenaenderung unter Linux (logische Pixel). Das
/// rahmenlose GTK-Fenster unter X11 hat keine eigenen, unter Wayland liegen
/// die von GTK ausserhalb der Inhaltsflaeche und stoeren sich nicht mit
/// diesen.
const double linuxResizeEdge = 6;

/// [WindowCaptionControls] mit window_manager (Windows, Linux, macOS).
class WindowManagerCaptionControls
    with WindowListener
    implements WindowCaptionControls {
  WindowManagerCaptionControls({required this.style, bool maximized = false})
    : _state = ValueNotifier<WindowFrameState>(
        WindowFrameState(maximized: maximized),
      ) {
    _wm.addListener(this);
  }

  /// Stil passend zur laufenden Plattform.
  static CaptionStyle platformStyle() =>
      Platform.isMacOS ? CaptionStyle.macos : CaptionStyle.buttons;

  final WindowManager _wm = WindowManager.instance;
  final ValueNotifier<WindowFrameState> _state;

  @override
  final CaptionStyle style;

  @override
  ValueListenable<WindowFrameState> get frameState => _state;

  void _update(WindowFrameState Function(WindowFrameState s) change) {
    _state.value = change(_state.value);
  }

  Future<void> _syncMaximized() async {
    try {
      final maximized = await _wm.isMaximized();
      _update((s) => s.copyWith(maximized: maximized));
    } on Object catch (e) {
      debugPrint('Fensterzustand nicht lesbar: $e');
    }
  }

  @override
  Future<void> minimize() => _wm.minimize();

  @override
  Future<void> toggleMaximize() async {
    if (await _wm.isMaximized()) {
      await _wm.unmaximize();
    } else {
      await _wm.maximize();
    }
  }

  // Derselbe Weg wie die Schliessen-Schaltflaeche des Systems: die
  // Schliessen-Anfrage geht an `WindowManagerDesktopWindow.onWindowClose`,
  // das je nach Einstellung in den Tray ausblendet oder beendet.
  @override
  Future<void> close() => _wm.close();

  @override
  Widget dragArea(Widget child) => DragToMoveArea(child: child);

  @override
  Widget maximizeButtonArea(Widget child) => MaximizeButtonArea(child: child);

  @override
  Widget resizeArea(Widget child, {required bool enabled}) => Platform.isLinux
      ? DragToResizeArea(
          resizeEdgeSize: linuxResizeEdge,
          enableResizeEdges: enabled ? null : const [],
          child: child,
        )
      : child;

  // ---------------------------------------------------------- Listener

  @override
  void onWindowFocus() => _update((s) => s.copyWith(active: true));

  @override
  void onWindowBlur() => _update((s) => s.copyWith(active: false));

  @override
  void onWindowMaximize() => _update((s) => s.copyWith(maximized: true));

  @override
  void onWindowUnmaximize() => _update((s) => s.copyWith(maximized: false));

  // Wiederherstellen nach Minimieren kann maximiert oder normal enden.
  @override
  void onWindowRestore() => unawaited(_syncMaximized());

  @override
  void onWindowEnterFullScreen() =>
      _update((s) => s.copyWith(fullScreen: true));

  @override
  void onWindowLeaveFullScreen() {
    _update((s) => s.copyWith(fullScreen: false));
    unawaited(_syncMaximized());
  }
}
