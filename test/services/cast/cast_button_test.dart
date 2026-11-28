import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/platform/airplay_button.dart';
import 'package:linefm_radio/services/cast/cast_button.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/cast/chrome_cast_service.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/in_memory_prefs_store.dart';
import '../../support/service_doubles.dart';
import '../../support/test_doubles.dart';
import 'cast_helpers.dart';

void main() {
  group('AirPlay', () {
    const channel = MethodChannel('test/airplay');
    final messenger =
        TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger;

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(channel, null);
    });

    test('Android/Desktop/Web: immer aus', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      messenger.setMockMethodCallHandler(channel, (_) async => true);
      expect(await airPlayAvailable(channel), isFalse);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(await airPlayAvailable(channel), isFalse);
    });

    test('iOS ohne native Umsetzung: aus', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await airPlayAvailable(channel), isFalse);
    });

    test('iOS/macOS mit nativer Umsetzung: an', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return call.method == 'isAvailable';
      });
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await airPlayAvailable(channel), isTrue);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(await airPlayAvailable(channel), isTrue);
    });
  });

  group('CastButton', () {
    Future<void> pump(WidgetTester tester, CastService service) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            ...noopServiceOverrides(cast: false),
            prefsProvider.overrideWithValue(InMemoryPrefsStore()),
            ...offlineDataOverrides(),
            castServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            theme: buildLinefmTheme(Brightness.dark),
            locale: const Locale('de'),
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Center(child: CastButton())),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('Noop auf Desktop: kein Knopf', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await pump(tester, const NoopCastService());
      expect(find.byIcon(Icons.cast), findsNothing);
    });

    testWidgets('verfügbar ohne Geräte: kein Knopf', (tester) async {
      final backend = FakeCastBackend();
      final service = ChromeCastService(
        backend: backend,
        resolveStreamUrl: url,
      );
      addTearDown(service.dispose);
      await pump(tester, service);
      expect(find.byIcon(Icons.cast), findsNothing);
    });

    testWidgets('Geräte da: Knopf, Sheet verbindet', (tester) async {
      final backend = FakeCastBackend();
      final service = ChromeCastService(
        backend: backend,
        resolveStreamUrl: url,
      );
      addTearDown(service.dispose);
      await pump(tester, service);
      backend.setDevices(<CastDevice>[tv]);
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.cast), findsOneWidget);

      await tester.tap(find.byIcon(Icons.cast));
      await tester.pumpAndSettle();
      expect(find.text('Wohnzimmer'), findsOneWidget);
      expect(backend.scans, contains(true));

      await tester.tap(find.text('Wohnzimmer'));
      await tester.pumpAndSettle();
      expect(service.state.connectedDevice, tv);
      expect(find.byIcon(Icons.cast_connected), findsOneWidget);
    });
  });
}
