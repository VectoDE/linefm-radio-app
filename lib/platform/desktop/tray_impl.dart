// tray_manager 0.9 bietet die bisherige API nur noch ueber `legacy.dart`
// an (als veraltet markiert).
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/platform/desktop/desktop_controller.dart';
import 'package:linefm_radio/platform/desktop/desktop_strings.dart';
import 'package:linefm_radio/platform/desktop/tray.dart';
import 'package:linefm_radio/platform/desktop/tray_icon_data.dart';
import 'package:tray_manager/legacy.dart';

/// Tray-Symbol mit Menue (Spec 2.2): aktueller Titel (deaktiviert),
/// Play/Stop, Sender-Untermenue, Mini-Player, Immer im Vordergrund,
/// Fenster zeigen, Beenden. Linksklick zeigt das Fenster.
class TrayManagerTrayController with TrayListener implements TrayController {
  TrayManagerTrayController(this._desktop);

  final DesktopController _desktop;
  final TrayManager _tray = TrayManager.instance;
  bool _available = false;
  String _signature = '';
  String _tooltip = '';

  @override
  bool get isAvailable => _available;

  @override
  Future<void> init() async {
    try {
      if (!_tray.isSupported) {
        debugPrint('Tray vom System nicht unterstuetzt.');
        return;
      }
      _tray.addListener(this);
      await _tray.setIcon(trayIconDataUri);
      _available = true;
      // Nachgeladene Senderliste: Untermenue neu aufbauen.
      stationsCatalogListenable.addListener(() => unawaited(refresh()));
      await refresh();
    } on Object catch (e) {
      // Kein Tray (z. B. GNOME ohne AppIndicator): App laeuft ohne weiter.
      _available = false;
      debugPrint('Tray nicht verfuegbar: $e');
    }
  }

  @override
  Future<void> setTooltip(String text) async {
    if (!_available || text == _tooltip) return;
    _tooltip = text;
    try {
      await _tray.setToolTip(text);
    } on Object catch (e) {
      debugPrint('Tray-Tooltip nicht gesetzt: $e');
    }
  }

  @override
  Future<void> refresh() async {
    if (!_available) return;
    final strings = DesktopStrings.system();
    final l10n = strings.l10n;
    final actions = _desktop.actions;
    final station = actions?.activeStation;
    final track = actions?.currentTrack;
    final playing = actions?.isPlaying ?? false;
    final mini = _desktop.miniMode.value;
    final onTop = _desktop.alwaysOnTop.value;

    final nowPlaying = track == null
        ? (station?.displayName ?? l10n.appTitle)
        : '${track.artist} - ${track.title}';
    final signature = <Object?>[
      l10n.localeName,
      nowPlaying,
      station?.slug,
      playing,
      mini,
      onTop,
      actions != null,
      for (final s in stationsCatalog) '${s.slug}=${s.displayName}',
    ].join('|');
    if (signature == _signature) return;
    _signature = signature;

    final menu = Menu(
      items: <MenuItem>[
        MenuItem(label: nowPlaying, disabled: true),
        MenuItem.separator(),
        MenuItem(
          label: playing ? l10n.trayStop : l10n.trayPlay,
          disabled: actions == null,
          onClick: (_) => unawaited(_desktop.togglePlayback()),
        ),
        MenuItem.submenu(
          label: l10n.trayStations,
          submenu: Menu(
            items: <MenuItem>[
              for (final s in stationsCatalog)
                MenuItem.checkbox(
                  label: s.displayName,
                  checked: s == station,
                  disabled: actions == null,
                  onClick: (_) => unawaited(_desktop.startStation(s)),
                ),
            ],
          ),
        ),
        MenuItem.separator(),
        MenuItem.checkbox(
          label: l10n.trayMiniPlayer,
          checked: mini,
          onClick: (_) => unawaited(_desktop.toggleMini()),
        ),
        MenuItem.checkbox(
          label: strings.alwaysOnTop,
          checked: onTop,
          onClick: (_) => unawaited(_desktop.toggleAlwaysOnTop()),
        ),
        MenuItem.separator(),
        MenuItem(
          label: l10n.trayShowWindow,
          onClick: (_) => unawaited(_showWindow()),
        ),
        MenuItem(
          label: l10n.trayQuit,
          onClick: (_) => unawaited(_desktop.quit()),
        ),
      ],
    );
    try {
      await _tray.setContextMenu(menu);
      final tip = playing ? '${l10n.appTitle}: $nowPlaying' : l10n.appTitle;
      // Windows kappt Tooltips bei 127 Zeichen.
      await setTooltip(tip.length > 120 ? '${tip.substring(0, 117)}...' : tip);
    } on Object catch (e) {
      debugPrint('Tray-Menue nicht gesetzt: $e');
    }
  }

  Future<void> _showWindow() async {
    if (_desktop.miniMode.value) {
      await _desktop.exitMini();
    } else {
      await _desktop.showWindow();
    }
  }

  @override
  void onTrayIconMouseUp() => unawaited(_showWindow());

  @override
  void onTrayIconRightMouseUp() {
    // Linux: Das Panel zeigt das exportierte Menue selbst.
    if (Platform.isLinux) return;
    unawaited(_tray.popUpContextMenu());
  }

  @override
  Future<void> dispose() async {
    _tray.removeListener(this);
    _available = false;
    try {
      await _tray.destroy();
    } on Object catch (e) {
      debugPrint('Tray nicht sauber abgebaut: $e');
    }
  }
}
