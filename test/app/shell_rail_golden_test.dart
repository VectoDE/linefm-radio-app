@Tags(<String>['golden'])
library;

// Bildvergleich der Navigation (Seitenleiste bei 1280 dp) in Deutsch und
// Englisch, Dunkel und Hell. Die Breite der Leiste muss in beiden
// Sprachen gleich sein. Referenzbilder entstehen auf dem CI-Runner, siehe
// docs/ENTWICKLUNG.md ("Goldens aktualisieren").
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

import '../golden_support.dart';
import 'app_host.dart';

Future<void> _matches(String name, Brightness brightness) => expectLater(
  find.byType(MaterialApp).first,
  matchesGoldenFile('goldens/${name}_${variant(brightness)}.png'),
);

AppHost _host(Brightness brightness) => AppHost(
  settings: AppSettings(
    autoplay: false,
    marquee: false,
    themeMode: brightness == Brightness.dark
        ? AppThemeMode.dark
        : AppThemeMode.light,
  ),
  extra: [
    // The reference images show the listener count (feature flag).
    appConfigProvider.overrideWithValue(
      const AppConfig(showListenerCount: true),
    ),
    platformInfoProvider.overrideWithValue(
      const PlatformInfo(isWeb: false, platform: TargetPlatform.windows),
    ),
  ],
);

void main() {
  setUpAll(prepareGoldens);

  for (final brightness in Brightness.values) {
    group('Golden Navigation ${variant(brightness)}', () {
      testWidgets('Seitenleiste 1280 dp: de und en gleich breit', (
        tester,
      ) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, const Size(1280, 800));
        final widths = <String, double>{};
        for (final lang in <String>['de', 'en']) {
          final host = _host(brightness);
          await pumpApp(
            tester,
            host,
            uri: Uri.parse('https://app.linefm.de/?lang=$lang'),
          );
          await settleImages(tester);
          final rail = find.byKey(const ValueKey<String>('shell-rail'));
          expect(rail, findsOneWidget);
          widths[lang] = tester.getSize(rail).width;
          await _matches('shell_rail_1280_$lang', brightness);
          await disposeApp(tester, host);
        }
        expect(widths['de'], widths['en']);
        expect(widths['de'], LinefmMetrics.railWidth);
      });
    });
  }
}
