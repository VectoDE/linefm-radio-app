// hotkey_manager 0.4 bietet die bisherige API nur noch ueber `legacy.dart`
// an (als veraltet markiert).
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart'
    show LogicalKeyboardKey, PlatformException;
import 'package:hotkey_manager/legacy.dart';
import 'package:linefm_radio/platform/desktop/desktop_controller.dart';
import 'package:linefm_radio/platform/desktop/hotkeys.dart';
// SMTC-Bruecke laeuft nur, wenn die Rust-Bibliothek geladen wurde; das zeigt
// nur dieses interne Flag. Ein zweites `SMTCWindows.initialize()` als Probe
// waere ein doppelter Init.
// ignore: implementation_imports
import 'package:smtc_windows/src/rust/frb_generated.dart' show RustLib;

/// Globale Tastenkuerzel mit hotkey_manager (siehe [DesktopHotkeys]).
class HotkeyManagerDesktopHotkeys implements DesktopHotkeys {
  HotkeyManagerDesktopHotkeys(this._desktop);

  final DesktopController _desktop;
  final HotKeyManager _manager = HotKeyManager.instance;
  final List<HotKey> _registered = <HotKey>[];

  /// Windows: laeuft die SMTC-Bruecke aus P10? Dann bekommt sie die
  /// Medientasten vom System; ein globales Kuerzel darauf wuerde sie
  /// abfangen.
  static bool get smtcActive {
    if (!Platform.isWindows) return false;
    try {
      // ignore: invalid_use_of_internal_member
      return RustLib.instance.initialized;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> register() async {
    final mod = <HotKeyModifier>[
      Platform.isMacOS ? HotKeyModifier.meta : HotKeyModifier.control,
      HotKeyModifier.alt,
    ];
    await _add(
      HotKey(key: LogicalKeyboardKey.keyP, modifiers: mod),
      _desktop.togglePlayback,
    );
    await _add(
      HotKey(key: LogicalKeyboardKey.arrowRight, modifiers: mod),
      () => _desktop.stepStation(1),
    );
    await _add(
      HotKey(key: LogicalKeyboardKey.arrowLeft, modifiers: mod),
      () => _desktop.stepStation(-1),
    );
    await _add(
      HotKey(key: LogicalKeyboardKey.arrowUp, modifiers: mod),
      () => _desktop.changeVolume(0.1),
    );
    await _add(
      HotKey(key: LogicalKeyboardKey.arrowDown, modifiers: mod),
      () => _desktop.changeVolume(-0.1),
    );
    await _add(
      HotKey(key: LogicalKeyboardKey.keyM, modifiers: mod),
      _desktop.toggleMini,
    );

    // Medientasten-Rueckfall: nur Windows ohne SMTC. Linux (MPRIS) und
    // macOS (audio_service) bekommen die Tasten vom System.
    if (Platform.isWindows && !smtcActive) {
      await _add(
        HotKey(key: LogicalKeyboardKey.mediaPlayPause),
        _desktop.togglePlayback,
      );
      await _add(HotKey(key: LogicalKeyboardKey.mediaStop), () async {
        if (_desktop.actions?.isPlaying ?? false) {
          await _desktop.togglePlayback();
        }
      });
      await _add(
        HotKey(key: LogicalKeyboardKey.mediaTrackNext),
        () => _desktop.stepStation(1),
      );
      await _add(
        HotKey(key: LogicalKeyboardKey.mediaTrackPrevious),
        () => _desktop.stepStation(-1),
      );
    }
  }

  Future<void> _add(HotKey hotKey, Future<void> Function() action) async {
    try {
      await _manager.register(
        hotKey,
        keyDownHandler: (_) => unawaited(action()),
      );
      _registered.add(hotKey);
    } on PlatformException catch (e) {
      if (e.code == 'unsupported_hotkey') {
        // hotkey_manager kennt fuer diese Taste keinen Systemcode (Windows:
        // erweiterte Scancodes der Medientasten liegen ueber 0xFF). Das ist
        // eine Plattformgrenze des Pakets, kein Fehler der App; die Medien-
        // tasten bedient SMTC bzw. das System.
        debugPrint(
          'Info: Tastenkuerzel ${hotKey.key} auf dieser '
          'Plattform nicht registrierbar (unsupported_hotkey).',
        );
      } else {
        debugPrint('Tastenkuerzel nicht registriert (${hotKey.key}): $e');
      }
    } on Object catch (e) {
      // Belegt oder vom System nicht erlaubt (z. B. Wayland ohne Portal).
      debugPrint('Tastenkuerzel nicht registriert (${hotKey.key}): $e');
    }
  }

  @override
  Future<void> unregisterAll() async {
    for (final hotKey in List<HotKey>.of(_registered)) {
      try {
        await _manager.unregister(hotKey);
      } on Object catch (e) {
        debugPrint('Tastenkuerzel nicht entfernt: $e');
      }
    }
    _registered.clear();
  }
}
