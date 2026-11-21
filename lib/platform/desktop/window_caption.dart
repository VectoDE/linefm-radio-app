import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Welche Titelleiste die App selbst zeichnet (Issue #87).
enum CaptionStyle {
  /// Keine eigene Leiste: Web, Mobil, Tests ohne Desktop-Umsetzung oder
  /// Desktop, wenn das Ausblenden der Systemleiste fehlschlug. Dann bleibt
  /// die Leiste des Betriebssystems stehen.
  none,

  /// Windows und Linux: Logo, Name und eigene Schaltflaechen Minimieren,
  /// Maximieren/Wiederherstellen, Schliessen rechts.
  buttons,

  /// macOS: Logo und Name, die Ampel-Schaltflaechen links bleiben nativ.
  macos,
}

/// Fensterzustand, den die Titelleiste darstellt.
@immutable
class WindowFrameState {
  const WindowFrameState({
    this.maximized = false,
    this.active = true,
    this.fullScreen = false,
  });

  final bool maximized;

  /// Fenster hat den Fokus des Systems (sonst gedaempfte Leiste).
  final bool active;

  /// Vollbild: keine Leiste, wie bei nativen Fenstern.
  final bool fullScreen;

  WindowFrameState copyWith({
    bool? maximized,
    bool? active,
    bool? fullScreen,
  }) => WindowFrameState(
    maximized: maximized ?? this.maximized,
    active: active ?? this.active,
    fullScreen: fullScreen ?? this.fullScreen,
  );

  @override
  bool operator ==(Object other) =>
      other is WindowFrameState &&
      other.maximized == maximized &&
      other.active == active &&
      other.fullScreen == fullScreen;

  @override
  int get hashCode => Object.hash(maximized, active, fullScreen);

  @override
  String toString() =>
      'WindowFrameState(maximized: $maximized, active: $active, '
      'fullScreen: $fullScreen)';
}

/// Was die eigene Titelleiste vom Fenster braucht. Die Umsetzung mit
/// window_manager liegt in `window_caption_impl.dart` (nur Desktop); dieses
/// Interface ist plattformneutral, damit Tests mit Fakes arbeiten.
abstract interface class WindowCaptionControls {
  CaptionStyle get style;

  ValueListenable<WindowFrameState> get frameState;

  Future<void> minimize();

  /// Maximiert bzw. stellt die vorige Groesse wieder her.
  Future<void> toggleMaximize();

  /// Wie die Schliessen-Schaltflaeche des Systems: Je nach Einstellung
  /// verschwindet das Fenster im Tray oder die App endet
  /// (`WindowManagerDesktopWindow.onWindowClose`).
  Future<void> close();

  /// Zieh-Flaeche: Ziehen verschiebt das Fenster (Andocken inklusive),
  /// Doppelklick wie in der Systemleiste, Rechtsklick oeffnet das
  /// Systemmenue (Windows, Linux).
  Widget dragArea(Widget child);

  /// Meldet die eigene Maximieren-Schaltflaeche dem System (Windows 11:
  /// Snap-Layouts beim Ueberfahren).
  Widget maximizeButtonArea(Widget child);

  /// Griffe zur Groessenaenderung an Kanten und Ecken, wo das System sie
  /// ohne Rahmen nicht selbst stellt (Linux). [enabled] false (maximiert,
  /// Vollbild, Mini-Fenster) schaltet sie ab, ohne den Baum zu aendern.
  Widget resizeArea(Widget child, {required bool enabled});
}

/// Standard ausserhalb des Desktops: keine eigene Leiste.
class NoopWindowCaptionControls implements WindowCaptionControls {
  NoopWindowCaptionControls();

  final ValueNotifier<WindowFrameState> _state = ValueNotifier(
    const WindowFrameState(),
  );

  @override
  CaptionStyle get style => CaptionStyle.none;

  @override
  ValueListenable<WindowFrameState> get frameState => _state;

  @override
  Future<void> minimize() async {}

  @override
  Future<void> toggleMaximize() async {}

  @override
  Future<void> close() async {}

  @override
  Widget dragArea(Widget child) => child;

  @override
  Widget maximizeButtonArea(Widget child) => child;

  @override
  Widget resizeArea(Widget child, {required bool enabled}) => child;
}
