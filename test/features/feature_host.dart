import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/features/legal/external_link.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_doubles.dart';

/// Konfiguration mit Umami, damit Telemetrie als konfiguriert gilt.
const AppConfig telemetryConfig = AppConfig(
  umamiUrl: 'https://stats.example.org',
  umamiWebsiteId: 'site-id',
);

/// Gemeinsame Testumgebung der Feature-Tests.
class FeatureHost {
  FeatureHost({
    AppConfig config = const AppConfig(),
    InMemoryPrefsStore? prefs,
    PlatformInfo? platform,
    DateTime? now,
    LegalAssetLoader? legalLoader,
    List<Override> extra = const <Override>[],
  }) : prefs = prefs ?? InMemoryPrefsStore(),
       clock = FakeClock(now ?? DateTime(2026, 11, 18, 6)),
       opened = <Uri>[] {
    ignoreCupertinoDelegateWarning();
    overrides = <Override>[
      prefsProvider.overrideWithValue(this.prefs),
      appConfigProvider.overrideWithValue(config),
      telemetryProvider.overrideWithValue(TelemetryHub(config: config)),
      clockProvider.overrideWithValue(clock),
      platformInfoProvider.overrideWithValue(
        platform ??
            const PlatformInfo(isWeb: false, platform: TargetPlatform.android),
      ),
      urlOpenerProvider.overrideWithValue((uri) async {
        opened.add(uri);
        return true;
      }),
      if (legalLoader != null)
        legalAssetLoaderProvider.overrideWithValue(legalLoader),
      ...extra,
    ];
  }

  final InMemoryPrefsStore prefs;
  final FakeClock clock;
  final List<Uri> opened;
  late final List<Override> overrides;

  Widget app(
    Widget home, {
    Locale locale = const Locale('de'),
    Brightness brightness = Brightness.dark,
    bool scaffold = true,
  }) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        theme: buildLinefmTheme(brightness),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: scaffold ? Scaffold(body: home) : home,
      ),
    );
  }
}

/// Setzt die Fenstergroesse (logische Pixel) fuer einen Test.
void useSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Unterdrueckt die Debug-Warnung "locale de is not supported by all
/// delegates" (Cupertino-Delegate fehlt absichtlich, siehe P01-Bericht). Der
/// Aufruf gehoert in den Testkoerper.
void ignoreCupertinoDelegateWarning() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if ('${details.exception}'.contains('is not supported by all of its')) {
      return;
    }
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}
