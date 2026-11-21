import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/platform/desktop/hotkeys.dart';
import 'package:linefm_radio/platform/desktop/tray.dart';
import 'package:linefm_radio/platform/desktop/window.dart';
import 'package:linefm_radio/platform/desktop/window_caption.dart';

/// Was Tray, Tastenkuerzel und Mini-Fenster von der App brauchen. Die
/// Umsetzung auf Riverpod-Basis liegt in `desktop_host.dart`.
abstract interface class DesktopActions {
  /// Spielt oder verbindet gerade (Menue zeigt dann "Stoppen").
  bool get isPlaying;

  Station get activeStation;

  Track? get currentTrack;

  /// Lautstaerke 0.1 bis 1.0.
  double get volume;

  Future<void> togglePlayback();

  Future<void> startStation(Station station);

  /// Naechster (+1) oder vorheriger (-1) Sender, mit Umlauf.
  Future<void> stepStation(int delta);

  Future<void> changeVolume(double delta);
}

/// Zentrale Schaltstelle der Desktop-Extras (Singleton). `initDesktop()` setzt
/// die nativen Umsetzungen ein, `DesktopHost` bindet die App-Aktionen. Auf
/// Web und Mobil bleiben die No-Op-Standardwerte stehen.
class DesktopController {
  DesktopController._();

  static final DesktopController instance = DesktopController._();

  DesktopWindow window = const NoopDesktopWindow();
  TrayController tray = const NoopTrayController();
  DesktopHotkeys hotkeys = const NoopDesktopHotkeys();

  /// Eigene Titelleiste (Issue #87). Bleibt [CaptionStyle.none], solange die
  /// Systemleiste steht (Web, Mobil, Fehler beim Ausblenden).
  WindowCaptionControls caption = NoopWindowCaptionControls();

  /// Macht ein Widget zur Fenster-Zieh-Flaeche (Mini-Fenster ist rahmenlos).
  Widget Function(Widget child) dragArea = (child) => child;

  /// true, sobald die Desktop-Umsetzung laeuft.
  bool active = false;

  /// Mini-Fenster (360x120) aktiv.
  final ValueNotifier<bool> miniMode = ValueNotifier<bool>(false);

  /// "Immer im Vordergrund" (im Mini-Fenster standardmaessig an).
  final ValueNotifier<bool> alwaysOnTop = ValueNotifier<bool>(false);

  /// Aufrufe eines zweiten Programmstarts (Windows): Argumente der
  /// Kommandozeile, z. B. `linefm://play?station=rap`. P21 wertet sie aus.
  final StreamController<List<String>> _secondInstance =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get secondInstanceArgs => _secondInstance.stream;

  DesktopActions? _actions;

  DesktopActions? get actions => _actions;

  bool _miniOnTop = true;
  bool _onTopBeforeMini = false;

  /// Von `DesktopHost` gesetzt; null beim Abbau.
  void bindActions(DesktopActions? actions) {
    _actions = actions;
    unawaited(tray.refresh());
  }

  /// Vorbelegung der gemerkten Mini-Fenster-Einstellung (nur beim Start).
  // ignore: use_setters_to_change_properties
  void restoreMiniOnTop({required bool value}) => _miniOnTop = value;

  void notifySecondInstance(List<String> args) {
    if (!_secondInstance.isClosed) _secondInstance.add(args);
  }

  Future<void> showWindow() async {
    await window.show();
  }

  Future<void> togglePlayback() async => _actions?.togglePlayback();

  Future<void> startStation(Station station) async =>
      _actions?.startStation(station);

  Future<void> stepStation(int delta) async => _actions?.stepStation(delta);

  Future<void> changeVolume(double delta) async =>
      _actions?.changeVolume(delta);

  Future<void> setAlwaysOnTop({required bool value}) async {
    alwaysOnTop.value = value;
    if (miniMode.value) _miniOnTop = value;
    await window.setAlwaysOnTop(value: value);
    await tray.refresh();
  }

  Future<void> toggleAlwaysOnTop() => setAlwaysOnTop(value: !alwaysOnTop.value);

  Future<void> enterMini() async {
    if (miniMode.value) return;
    _onTopBeforeMini = alwaysOnTop.value;
    miniMode.value = true;
    alwaysOnTop.value = _miniOnTop;
    await window.enterMini(alwaysOnTop: _miniOnTop);
    await tray.refresh();
  }

  Future<void> exitMini() async {
    if (!miniMode.value) return;
    miniMode.value = false;
    alwaysOnTop.value = _onTopBeforeMini;
    await window.exitMini(alwaysOnTop: _onTopBeforeMini);
    await tray.refresh();
  }

  Future<void> toggleMini() => miniMode.value ? exitMini() : enterMini();

  /// Beendet die App: Kuerzel und Tray abbauen, dann Fenster zerstoeren.
  Future<void> quit() async {
    await hotkeys.unregisterAll();
    await tray.dispose();
    await window.quit();
  }
}
