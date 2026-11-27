@Tags(<String>['golden'])
library;

// Bildvergleich des App-Rahmens (Header mit Zahnrad, Navigation mit
// Favoriten-Zaehler, Mini-Player) und der Einstellungen in Dark und Hell. Referenzbilder
// entstehen auf dem CI-Runner, siehe docs/ENTWICKLUNG.md ("Goldens
// aktualisieren").
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:material_ui/material_ui.dart';

import '../golden_support.dart';
import 'app_host.dart';

Future<void> _matches(String name, Brightness brightness) => expectLater(
  find.byType(MaterialApp).first,
  matchesGoldenFile('goldens/${name}_${variant(brightness)}.png'),
);

AppHost _host(Brightness brightness) {
  final host = AppHost(
    settings: AppSettings(
      autoplay: false,
      marquee: false,
      themeMode: brightness == Brightness.dark
          ? AppThemeMode.dark
          : AppThemeMode.light,
    ),
    extra: [
      platformInfoProvider.overrideWithValue(
        const PlatformInfo(isWeb: false, platform: TargetPlatform.android),
      ),
    ],
  );
  host.prefs.writeFavorites(<Favorite>[
    for (var i = 0; i < 7; i++)
      Favorite(
        key: 'linefm:artist $i:titel $i',
        stationSlug: 'linefm',
        title: 'Titel $i',
        artist: 'Artist $i',
        savedAt: DateTime(2026, 11, 18, 20, i),
      ),
  ]).ignore();
  return host;
}

void main() {
  setUpAll(prepareGoldens);

  for (final brightness in Brightness.values) {
    group('Golden ${variant(brightness)}', () {
      testWidgets('App-Rahmen Handy: Sender', (tester) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, const Size(390, 844));
        final host = _host(brightness);
        await pumpApp(tester, host);
        await settleImages(tester);
        await _matches('shell_stations_390', brightness);
        await disposeApp(tester, host);
      });

      testWidgets('App-Rahmen Handy: Einstellungen', (tester) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, const Size(390, 844));
        final host = _host(brightness);
        await pumpApp(tester, host);
        host.container.read(navigationProvider.notifier).go(AppScreen.settings);
        await settleApp(tester);
        await settleImages(tester);
        await _matches('shell_settings_390', brightness);
        await disposeApp(tester, host);
      });

      testWidgets('App-Rahmen Handy: Favoriten aktiv, Englisch', (
        tester,
      ) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, const Size(390, 844));
        final host = _host(brightness);
        await pumpApp(
          tester,
          host,
          uri: Uri.parse('https://app.linefm.de/?lang=en'),
        );
        host.container
            .read(navigationProvider.notifier)
            .go(AppScreen.favorites);
        await settleApp(tester);
        await settleImages(tester);
        await _matches('shell_favorites_390_en', brightness);
        await disposeApp(tester, host);
      });
    });
  }
}
