// Keyboard shortcuts of the app shell, run with the Linux target platform so
// the Linux desktop build (Ctrl instead of Cmd, no media keys) is covered in
// CI without a display server. A real Linux session adds the window manager
// and input method; that part stays a manual check in docs/GERAETETESTS.md.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';

import '../app/app_host.dart';
import '../golden_support.dart';

final TargetPlatformVariant _linux = TargetPlatformVariant.only(
  TargetPlatform.linux,
);

Future<AppHost> _open(
  WidgetTester tester, {
  AppSettings settings = const AppSettings(autoplay: false),
}) async {
  ignoreDelegateWarning();
  useSize(tester, 1000, 720);
  final host = AppHost(settings: settings);
  await pumpApp(tester, host);
  return host;
}

void main() {
  testWidgets('digits 1 to 6 start the matching station', (tester) async {
    final host = await _open(tester);
    for (var i = 0; i < stationsCatalog.length && i < 6; i++) {
      await tester.sendKeyEvent(
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit3,
          LogicalKeyboardKey.digit4,
          LogicalKeyboardKey.digit5,
          LogicalKeyboardKey.digit6,
        ][i],
      );
      await settleApp(tester);
      expect(host.active, stationsCatalog[i], reason: 'digit ${i + 1}');
      expect(host.playback.state.isPlaying, isTrue, reason: 'digit ${i + 1}');
    }
    await disposeApp(tester, host);
  }, variant: _linux);

  testWidgets('space toggles playback', (tester) async {
    final host = await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await settleApp(tester);
    expect(host.playback.state.isPlaying, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleApp(tester);
    expect(host.playback.state.isPlaying, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleApp(tester);
    expect(host.playback.state.isPlaying, isTrue);
    await disposeApp(tester, host);
  }, variant: _linux);

  testWidgets('Ctrl+comma opens the settings, Escape goes back', (
    tester,
  ) async {
    final host = await _open(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settleApp(tester);
    expect(host.container.read(navigationProvider), AppScreen.settings);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleApp(tester);
    expect(host.container.read(navigationProvider), AppScreen.stations);
    await disposeApp(tester, host);
  }, variant: _linux);

  testWidgets('F adds the current track to the favorites and removes it', (
    tester,
  ) async {
    final host = await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await settleApp(tester);
    expect(host.container.read(favoritesProvider), isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await settleApp(tester);
    expect(host.container.read(favoritesProvider), hasLength(1));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await settleApp(tester);
    expect(host.container.read(favoritesProvider), isEmpty);
    await disposeApp(tester, host);
  }, variant: _linux);

  testWidgets('S starts a shuffled station', (tester) async {
    final host = await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await settleApp(tester);
    expect(host.playback.state.isPlaying, isTrue);
    await disposeApp(tester, host);
  }, variant: _linux);

  testWidgets('single-character shortcuts can be switched off (WCAG 2.1.4)', (
    tester,
  ) async {
    final host = await _open(
      tester,
      settings: const AppSettings(autoplay: false, keyboardShortcuts: false),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await settleApp(tester);
    expect(host.playback.state.isPlaying, isFalse);
    // Escape and Ctrl+comma are not single-character shortcuts and stay.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settleApp(tester);
    expect(host.container.read(navigationProvider), AppScreen.settings);
    await disposeApp(tester, host);
  }, variant: _linux);

  testWidgets('Alt combinations are left to the window manager', (
    tester,
  ) async {
    final host = await _open(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await settleApp(tester);
    expect(host.playback.state.isPlaying, isFalse);
    await disposeApp(tester, host);
  }, variant: _linux);
}
