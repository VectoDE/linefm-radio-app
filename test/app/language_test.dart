import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/app.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/features/settings/settings_screen.dart';
import 'package:linefm_radio/l10n/system_l10n.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

import '../support/in_memory_prefs_store.dart';
import '../support/service_doubles.dart';
import 'app_host.dart';

const _noAutoplay = AppSettings(autoplay: false);

Set<String> _keys(String file) {
  final map = jsonDecode(
    File('lib/l10n/$file').readAsStringSync(),
  ) as Map<String, dynamic>;
  return map.keys.where((k) => !k.startsWith('@')).toSet();
}

Future<void> _openSettings(WidgetTester tester, AppHost host) async {
  useSize(tester, 600, 2600);
  await pumpApp(tester, host, uri: Uri.parse('https://app.linefm.de/'));
  host.container.read(navigationProvider.notifier).go(AppScreen.settings);
  await settleApp(tester);
  expect(find.byType(SettingsScreen), findsOneWidget);
}

void main() {
  tearDown(() => appLanguageOverride = null);

  group('ARB-Dateien', () {
    test('Deutsch und Englisch haben dieselben Schluessel', () {
      final de = _keys('app_de.arb');
      final en = _keys('app_en.arb');
      expect(de.difference(en), isEmpty, reason: 'fehlt in app_en.arb');
      expect(en.difference(de), isEmpty, reason: 'fehlt in app_de.arb');
    });

    test('Platzhalter stimmen in beiden Sprachen ueberein', () {
      final de = jsonDecode(
        File('lib/l10n/app_de.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      final en = jsonDecode(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      final placeholder = RegExp(r'\{(\w+)\s*[,}]');
      for (final key in _keys('app_de.arb')) {
        final a = placeholder
            .allMatches('${de[key]}')
            .map((m) => m.group(1))
            .toSet();
        final b = placeholder
            .allMatches('${en[key]}')
            .map((m) => m.group(1))
            .toSet();
        expect(b, a, reason: 'Platzhalter in $key');
      }
    });
  });

  group('Sprachwahl (Modell)', () {
    test('Standard ist Systemsprache; JSON-Rundlauf und Tippfehler', () {
      expect(const AppSettings().language, AppLanguage.system);
      final en = const AppSettings().copyWith(language: AppLanguage.en);
      expect(AppSettings.fromJson(en.toJson()).language, AppLanguage.en);
      expect(
        AppSettings.fromJson(<String, Object?>{'language': 'fr'}).language,
        AppLanguage.system,
      );
      expect(
        AppSettings.fromJson(<String, Object?>{'language': 7}).language,
        AppLanguage.system,
      );
      expect(AppSettings.fromJson(null).language, AppLanguage.system);
    });

    test('Rangfolge: URL vor Wahl vor System', () {
      expect(
        chooseLocale(urlLocale: const Locale('de'), language: AppLanguage.en),
        const Locale('de'),
      );
      expect(chooseLocale(language: AppLanguage.en), const Locale('en'));
      expect(chooseLocale(language: AppLanguage.de), const Locale('de'));
      expect(chooseLocale(language: AppLanguage.system), isNull);
    });

    test('Wahl bleibt nach Neustart des Providers, Loeschen setzt zurueck', () {
      final prefs = InMemoryPrefsStore();
      ProviderContainer open() => ProviderContainer(
        overrides: [
          ...noopServiceOverrides(),
          prefsProvider.overrideWithValue(prefs),
        ],
      );

      final first = open();
      first
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(language: AppLanguage.en));
      expect(first.read(settingsProvider).language, AppLanguage.en);
      first.dispose();

      final second = open();
      expect(second.read(settingsProvider).language, AppLanguage.en);

      // "Speicher loeschen": zurueck auf die Systemsprache.
      prefs.clearAll();
      second.invalidate(settingsProvider);
      expect(second.read(settingsProvider).language, AppLanguage.system);
      second.dispose();
    });

    test('Texte ohne BuildContext folgen der gewaehlten Sprache', () {
      appLanguageOverride = 'de';
      expect(systemLocalizations().settingsTitle, 'Einstellungen');
      appLanguageOverride = 'en';
      expect(systemLocalizations().settingsTitle, 'Settings');
      appLanguageOverride = 'fr';
      expect(appLanguageOverride, isNull);
    });
  });

  group('Sprachwahl (App)', () {
    testWidgets('Systemsprache Deutsch, Englisch und Rueckfall Englisch', (
      tester,
    ) async {
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      tester.platformDispatcher.localesTestValue = const <Locale>[
        Locale('de', 'AT'),
      ];
      var host = AppHost(settings: _noAutoplay);
      await _openSettings(tester, host);
      expect(find.text('Sprache'), findsOneWidget);
      await disposeApp(tester, host);

      tester.platformDispatcher.localesTestValue = const <Locale>[
        Locale('fr', 'FR'),
      ];
      host = AppHost(settings: _noAutoplay);
      await _openSettings(tester, host);
      expect(find.text('Language'), findsOneWidget);
      await disposeApp(tester, host);
    });

    testWidgets('Wechsel wirkt sofort, auch gegen ?lang= der Adresse', (
      tester,
    ) async {
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
      final host = AppHost(settings: _noAutoplay);
      useSize(tester, 600, 2600);
      // Adresse verlangt Deutsch: schlaegt die Systemsprache.
      await pumpApp(tester, host);
      host.container.read(navigationProvider.notifier).go(AppScreen.settings);
      await settleApp(tester);
      expect(find.text('Sprache'), findsOneWidget);

      await tester.tap(find.text('English'));
      await settleApp(tester);
      expect(find.text('Language'), findsOneWidget);
      expect(host.container.read(settingsProvider).language, AppLanguage.en);
      expect(appLanguageOverride, 'en');
      // Gespeichert.
      expect(host.prefs.readSettings().language, AppLanguage.en);

      await tester.tap(find.text('Deutsch'));
      await settleApp(tester);
      expect(find.text('Sprache'), findsOneWidget);
      expect(appLanguageOverride, 'de');

      await tester.tap(find.text('Systemsprache'));
      await settleApp(tester);
      // Systemsprache der Testumgebung ist Englisch.
      expect(find.text('Language'), findsOneWidget);
      expect(appLanguageOverride, isNull);
      await disposeApp(tester, host);
    });

    testWidgets('Gespeicherte Wahl gilt beim Start vor der Systemsprache', (
      tester,
    ) async {
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
      final host = AppHost(
        settings: _noAutoplay.copyWith(language: AppLanguage.de),
      );
      await _openSettings(tester, host);
      expect(find.text('Sprache'), findsOneWidget);
      await disposeApp(tester, host);
    });

    testWidgets('Semantik: Schaltflaechen mit Auswahlzustand, Eigennamen', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
      final host = AppHost(
        settings: _noAutoplay.copyWith(language: AppLanguage.en),
      );
      await _openSettings(tester, host);

      SemanticsNode button(String label) => find.semantics
          .byPredicate((n) => n.label == label && n.flagsCollection.isButton)
          .evaluate()
          .single;
      expect(button('English').flagsCollection.isSelected, Tristate.isTrue);
      expect(button('Deutsch').flagsCollection.isSelected, Tristate.isFalse);
      expect(
        button('System language').flagsCollection.isSelected,
        Tristate.isFalse,
      );
      expect(
        find.semantics
            .byPredicate(
              (n) => n.label == 'Language' && n.flagsCollection.isHeader,
            )
            .evaluate(),
        isNotEmpty,
      );
      await disposeApp(tester, host);
      handle.dispose();
    });
  });

  group('Navigation bleibt beim Sprachwechsel gleich breit', () {
    for (final width in <double>[1280, 1600]) {
      testWidgets('Seitenleiste bei $width dp: Deutsch = Englisch', (
        tester,
      ) async {
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
        final host = AppHost(settings: _noAutoplay);
        useSize(tester, width, 1000);
        await pumpApp(tester, host);
        host.container.read(navigationProvider.notifier).go(AppScreen.settings);
        await settleApp(tester);
        final rail = find.byKey(const ValueKey<String>('shell-rail'));
        expect(rail, findsOneWidget);
        expect(find.text('Sprache'), findsOneWidget);
        final de = tester.getSize(rail).width;
        final railDe = tester.getSize(find.byType(NavigationRail)).width;

        await tester.tap(find.text('English'));
        await settleApp(tester);
        expect(find.text('Language'), findsOneWidget);
        final en = tester.getSize(rail).width;
        final railEn = tester.getSize(find.byType(NavigationRail)).width;

        expect(en, de);
        expect(railEn, railDe);
        expect(de, LinefmMetrics.railWidth);
        // Lange Beschriftung bleibt fuer den Screenreader vollstaendig.
        await tester.tap(find.text('Deutsch'));
        await settleApp(tester);
        expect(
          find.descendant(of: rail, matching: find.text('FAVORITEN')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await disposeApp(tester, host);
      });
    }
  });
}
