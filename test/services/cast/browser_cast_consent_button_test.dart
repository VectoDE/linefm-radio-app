import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/consent/cast_consent.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/cast/browser_cast.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_button.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/cast/chrome_cast_service.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/in_memory_prefs_store.dart';
import '../../support/service_doubles.dart';
import '../../support/test_doubles.dart';
import 'browser_cast_helpers.dart';

void main() {
  group('CastConsentNotifier', () {
    test('null when the browser cannot cast', () {
      final c = ProviderContainer(
        overrides: <Override>[
          ...noopServiceOverrides(),
          browserCastBridgeProvider.overrideWithValue(
            FakeBrowserCastBridge(supported: false, decision: true),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(castConsentProvider), isNull);
      c.read(castConsentProvider.notifier).set(value: true);
      expect(c.read(castConsentProvider), isNull);
    });

    test('grant, deny and reset go to the bridge', () {
      final bridge = FakeBrowserCastBridge();
      final c = ProviderContainer(
        overrides: <Override>[
          ...noopServiceOverrides(),
          browserCastBridgeProvider.overrideWithValue(bridge),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(castConsentProvider), isNull);
      c.read(castConsentProvider.notifier).set(value: true);
      expect(bridge.decision, isTrue);
      expect(c.read(castConsentProvider), isTrue);
      c.read(castConsentProvider.notifier).set(value: false);
      expect(bridge.decision, isFalse);
      c.read(castConsentProvider.notifier).reset();
      expect(bridge.resets, 1);
      expect(c.read(castConsentProvider), isNull);
    });
  });

  group('CastButton on the web', () {
    final defaultFactory = castBackendFactory;
    tearDown(() {
      castBackend = null;
      castBackendFactory = defaultFactory;
      resetCastInitForTest();
    });

    Future<(ProviderContainer, FakeBrowserCastBridge, List<int>)> pump(
      WidgetTester tester, {
      bool? decision,
    }) async {
      castBackend = null;
      resetCastInitForTest();
      final bridge = FakeBrowserCastBridge(decision: decision);
      final starts = <int>[];
      castBackendFactory = () async {
        starts.add(1);
        return createBrowserCastBackend(bridge);
      };
      final container = ProviderContainer(
        overrides: <Override>[
          ...noopServiceOverrides(cast: false),
          prefsProvider.overrideWithValue(InMemoryPrefsStore()),
          ...offlineDataOverrides(),
          browserCastBridgeProvider.overrideWithValue(bridge),
          castServiceProvider.overrideWith(createCastService),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            theme: buildLinefmTheme(Brightness.dark),
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Center(child: CastButton())),
          ),
        ),
      );
      return (container, bridge, starts);
    }

    testWidgets('button visible before consent, tap asks first', (
      tester,
    ) async {
      final (container, bridge, starts) = await pump(tester);
      expect(find.byIcon(Icons.cast), findsOneWidget);
      await tester.tap(find.byIcon(Icons.cast));
      await tester.pumpAndSettle();
      expect(find.byType(CastConsentDialog), findsOneWidget);
      expect(starts, isEmpty);
      await tester.tap(find.text('Ablehnen'));
      await tester.pumpAndSettle();
      expect(bridge.decision, isFalse);
      expect(bridge.sdkLoads, 0, reason: 'declined: nothing from Google');
      expect(starts, isEmpty);
      expect(container.read(castServiceProvider), isA<NoopCastService>());
    });

    testWidgets('allow loads the SDK and offers the browser picker', (
      tester,
    ) async {
      final (container, bridge, starts) = await pump(tester);
      await tester.tap(find.byIcon(Icons.cast));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Erlauben'));
      await tester.pumpAndSettle();
      expect(bridge.decision, isTrue);
      expect(bridge.sdkLoads, 1);
      expect(starts, hasLength(1));
      expect(container.read(castServiceProvider), isA<ChromeCastService>());
      expect(find.byType(CastSheet), findsOneWidget);
      await tester.tap(find.text('Gerät auswählen'));
      await tester.pumpAndSettle();
      expect(bridge.sessionRequests, 1);
    });

    testWidgets('earlier consent: no dialog', (tester) async {
      final (_, bridge, starts) = await pump(tester, decision: true);
      await tester.tap(find.byIcon(Icons.cast));
      await tester.pumpAndSettle();
      expect(find.byType(CastConsentDialog), findsNothing);
      expect(starts, hasLength(1));
      expect(bridge.sdkLoads, 1);
    });

    testWidgets('unsupported browser: no button', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      castBackend = null;
      resetCastInitForTest();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            ...noopServiceOverrides(),
            prefsProvider.overrideWithValue(InMemoryPrefsStore()),
            ...offlineDataOverrides(),
            browserCastBridgeProvider.overrideWithValue(
              FakeBrowserCastBridge(supported: false),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            theme: buildLinefmTheme(Brightness.dark),
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
      expect(find.byIcon(Icons.cast), findsNothing);
    });
  });
}
