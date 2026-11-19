// window_manager 0.7 bietet die bisherige API nur noch ueber `legacy.dart`
// an (als veraltet markiert); die native API hat keinen Close-Abfang.
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:linefm_radio/platform/desktop/saved_bounds.dart';
import 'package:linefm_radio/platform/desktop/window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/legacy.dart';

/// Fenstertitel wie in der Web-App (und im Windows-Runner fuer die
/// Einzelinstanz-Suche; dort identisch halten).
const String desktopWindowTitle = 'LINEFM | Radio';

/// Mini-Fenster (Spec 4.3).
const Size miniWindowSize = Size(360, 120);

/// Mindestgroesse des normalen Fensters (Kompakt-Layout, Spec 4.3).
const Size normalWindowMinimum = Size(360, 520);

const Size _defaultWindowSize = Size(1280, 720);

// Schluessel ausserhalb von `PrefsKeys`, damit die Einwilligungslogik der
// App unberuehrt bleibt; geschrieben wird nur mit Speicher-Bestaetigung.
const String _consentKey = 'linefm-storage-notice-dismissed';
const String _closeToTrayKey = 'linefm-setting-close-to-tray';
const String _windowKey = 'linefm-desktop-window';
const String _miniKey = 'linefm-desktop-mini';

/// Fenster-Umsetzung mit window_manager.
class WindowManagerDesktopWindow with WindowListener implements DesktopWindow {
  WindowManagerDesktopWindow(this._prefs);

  final SharedPreferences? _prefs;
  final WindowManager _wm = WindowManager.instance;

  bool _closeToTray = true;
  bool _trayAvailable = true;
  bool _mini = false;
  Timer? _saveTimer;
  SavedBounds? _normalBounds;

  bool get _consent => _prefs?.getBool(_consentKey) ?? false;

  /// Liest die gemerkten Werte (nur mit Speicher-Bestaetigung).
  static bool readCloseToTray(SharedPreferences? prefs) {
    if (prefs == null || !(prefs.getBool(_consentKey) ?? false)) return true;
    return prefs.getBool(_closeToTrayKey) ?? true;
  }

  static bool readMiniOnTop(SharedPreferences? prefs) {
    final saved = _readMini(prefs);
    return saved?.onTop ?? true;
  }

  static ({Offset position, bool onTop})? _readMini(SharedPreferences? prefs) {
    if (prefs == null || !(prefs.getBool(_consentKey) ?? false)) return null;
    final parts = prefs.getString(_miniKey)?.split(';');
    if (parts == null || parts.length < 3) return null;
    final x = double.tryParse(parts[0]);
    final y = double.tryParse(parts[1]);
    if (x == null || y == null || x.abs() > 20000 || y.abs() > 20000) {
      return null;
    }
    return (position: Offset(x, y), onTop: parts[2] != '0');
  }

  /// Titel, Mindestgroesse und gemerkte Groesse/Position setzen. Laeuft vor
  /// `runApp`, das Fenster wird erst mit dem ersten Frame sichtbar.
  Future<void> init({required bool closeToTray}) async {
    await _wm.ensureInitialized();
    _wm.addListener(this);
    _closeToTray = closeToTray;
    await _wm.setPreventClose(closeToTray);
    await _wm.setTitle(desktopWindowTitle);
    await _wm.setMinimumSize(normalWindowMinimum);

    final saved = _consent
        ? SavedBounds.decode(
            _prefs?.getString(_windowKey),
            minimum: normalWindowMinimum,
          )
        : null;
    if (saved == null) {
      await _wm.setSize(_defaultWindowSize);
      await _wm.center();
    } else {
      await _wm.setBounds(saved.rect);
      if (saved.maximized) await _wm.maximize();
      _normalBounds = saved;
    }
  }

  @override
  Future<void> show() async {
    if (await _wm.isMinimized()) await _wm.restore();
    await _wm.show();
    await _wm.focus();
  }

  @override
  Future<void> hide() => _wm.hide();

  @override
  Future<void> setAlwaysOnTop({required bool value}) async {
    await _wm.setAlwaysOnTop(value);
    if (_mini) await _saveMini(onTop: value);
  }

  @override
  set trayAvailable(bool value) {
    _trayAvailable = value;
    if (!value) unawaited(setCloseToTray(value: false));
  }

  @override
  Future<void> setCloseToTray({required bool value}) async {
    _closeToTray = value && _trayAvailable;
    await _wm.setPreventClose(_closeToTray);
  }

  @override
  Future<void> enterMini({required bool alwaysOnTop}) async {
    if (_mini) return;
    // Normales Fenster merken, bevor das Mini-Fenster die Werte aendert.
    _saveTimer?.cancel();
    final bounds = await _currentNormalBounds();
    _normalBounds = bounds;
    await _saveNormal(bounds);
    _mini = true;
    await _wm.setMinimumSize(miniWindowSize);
    if (await _wm.isMaximized()) await _wm.unmaximize();
    await _wm.setResizable(false);
    await _wm.setAsFrameless();
    final mini = _readMini(_prefs);
    final position = mini?.position ?? bounds.rect.topLeft;
    await _wm.setBounds(
      Rect.fromLTWH(
        position.dx,
        position.dy,
        miniWindowSize.width,
        miniWindowSize.height,
      ),
    );
    await _wm.setAlwaysOnTop(alwaysOnTop);
    await show();
  }

  @override
  Future<void> exitMini({required bool alwaysOnTop}) async {
    if (!_mini) return;
    _saveTimer?.cancel();
    await _saveMini(onTop: await _wm.isAlwaysOnTop());
    _mini = false;
    await _wm.setAlwaysOnTop(alwaysOnTop);
    await _wm.setTitleBarStyle(TitleBarStyle.normal);
    await _wm.setResizable(true);
    await _wm.setMinimumSize(normalWindowMinimum);
    final bounds = _normalBounds;
    if (bounds != null) {
      await _wm.setBounds(bounds.rect);
      if (bounds.maximized) await _wm.maximize();
    }
    await show();
  }

  @override
  Future<void> quit() async {
    _saveTimer?.cancel();
    await _wm.setPreventClose(false);
    await _wm.destroy();
  }

  // ---------------------------------------------------------- Listener

  @override
  void onWindowClose() {
    if (_closeToTray) {
      unawaited(hide());
    } else {
      unawaited(quit());
    }
  }

  @override
  void onWindowResized() => _scheduleSave();

  @override
  void onWindowMoved() => _scheduleSave();

  @override
  void onWindowMaximize() => _scheduleSave();

  @override
  void onWindowUnmaximize() => _scheduleSave();

  // ---------------------------------------------------------- Speichern

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () {
      unawaited(_save());
    });
  }

  Future<void> _save() async {
    try {
      if (_mini) {
        await _saveMini(onTop: await _wm.isAlwaysOnTop());
        return;
      }
      final bounds = await _currentNormalBounds();
      _normalBounds = bounds;
      await _saveNormal(bounds);
    } on Object catch (e) {
      debugPrint('Fensterposition nicht gespeichert: $e');
    }
  }

  /// Bei maximiertem Fenster bleibt die letzte normale Geometrie erhalten,
  /// das Maximieren wird nur als Kennzeichen gemerkt.
  Future<SavedBounds> _currentNormalBounds() async {
    final maximized = await _wm.isMaximized();
    if (maximized && _normalBounds != null) {
      return SavedBounds(_normalBounds!.rect, maximized: true);
    }
    return SavedBounds(await _wm.getBounds(), maximized: maximized);
  }

  Future<void> _saveNormal(SavedBounds bounds) async {
    final prefs = _prefs;
    if (prefs == null || !_consent) return;
    await prefs.setString(_windowKey, bounds.encode());
  }

  Future<void> _saveMini({required bool onTop}) async {
    final prefs = _prefs;
    if (prefs == null || !_consent) return;
    final position = await _wm.getPosition();
    await prefs.setString(
      _miniKey,
      '${position.dx.round()};${position.dy.round()};${onTop ? 1 : 0}',
    );
  }
}
