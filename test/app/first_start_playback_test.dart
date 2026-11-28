import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:material_ui/material_ui.dart';

import 'app_host.dart';

const PlatformInfo _desktop = PlatformInfo(
  isWeb: false,
  platform: TargetPlatform.windows,
);

void main() {
  group('Native first start: playback waits for the storage notice', () {
    testWidgets('no sound behind the popup, playback after "Verstanden"', (
      tester,
    ) async {
      useSize(tester, 390, 900);
      // Android waits for the foreground first; the desktop path starts at once.
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final host = AppHost(
        settings: const AppSettings(),
        platform: _desktop,
        storageConfirmed: false,
      );
      await pumpApp(tester, host);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(host.playback.state.isPlaying, isFalse);

      await tester.tap(find.widgetWithText(FilledButton, 'Verstanden'));
      await settleApp(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(host.playback.state.isPlaying, isTrue);
      await disposeApp(tester, host);
    });

    testWidgets('later starts (notice confirmed) play at once', (tester) async {
      useSize(tester, 390, 900);
      // Android waits for the foreground first; the desktop path starts at once.
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final host = AppHost(settings: const AppSettings(), platform: _desktop);
      await pumpApp(tester, host);

      expect(find.byType(AlertDialog), findsNothing);
      expect(host.playback.state.isPlaying, isTrue);
      await disposeApp(tester, host);
    });
  });
}
