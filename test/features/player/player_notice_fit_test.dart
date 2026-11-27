import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_host.dart';
import '../../golden_support.dart';

void main() {
  // Real fonts: the notice height depends on the text wrapping.
  setUpAll(loadAppFonts);

  for (final (width, height) in <(double, double)>[(390, 844), (360, 760)]) {
    testWidgets('$width x $height: player actions stay above the web notice', (
      tester,
    ) async {
      useSize(tester, width, height);
      final host = AppHost(
        settings: const AppSettings(autoplay: false),
        platform: const PlatformInfo(
          isWeb: true,
          platform: TargetPlatform.android,
        ),
        storageConfirmed: false,
      );
      await pumpApp(tester, host);
      host.container.read(navigationProvider.notifier).go(AppScreen.player);
      await settleApp(tester);

      final notice = tester.getRect(
        find.byKey(const ValueKey<String>('storage-notice-on')),
      );
      final action = tester.getRect(find.text('Song öffnen').first);
      expect(action.bottom, lessThanOrEqualTo(notice.top));
      expect(tester.takeException(), isNull);
      await disposeApp(tester, host);
    });
  }
}
