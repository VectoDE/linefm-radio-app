import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/features/consent/google_consent.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/analytics/google_analytics_bridge.dart';
import 'package:material_ui/material_ui.dart';

class _FakeBridge implements GoogleAnalyticsBridge {
  _FakeBridge([this.decision]);

  @override
  bool? decision;
  final List<String> calls = <String>[];

  @override
  void configure({required String gtmId, required String ga4Id}) =>
      calls.add('configure:$gtmId:$ga4Id');

  @override
  void grant() {
    calls.add('grant');
    decision = true;
  }

  @override
  void deny() {
    calls.add('deny');
    decision = false;
  }

  @override
  void reset() {
    calls.add('reset');
    decision = null;
  }
}

const _ids = AppConfig(gtmId: 'GTM-TEST000', ga4MeasurementId: 'G-TEST000000');

ProviderContainer _container(_FakeBridge bridge, {required bool enabled}) =>
    ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_ids),
        googleAnalyticsBridgeProvider.overrideWithValue(bridge),
        googleAnalyticsEnabledProvider.overrideWithValue(enabled),
      ],
    );

void main() {
  group('AppConfig', () {
    test('nur gueltige IDs zaehlen', () {
      expect(const AppConfig().googleAnalyticsIdsSet, isFalse);
      expect(_ids.googleAnalyticsIdsSet, isTrue);
      expect(const AppConfig(gtmId: 'GTM-1"x').validGtmId, isEmpty);
      expect(const AppConfig(ga4MeasurementId: 'UA-123').validGa4Id, isEmpty);
      // Ausserhalb des Webs nie aktiv (Tests laufen in der Dart-VM).
      expect(_ids.googleAnalyticsConfigured, isFalse);
    });
  });

  group('GoogleConsentNotifier', () {
    test('ohne Konfiguration: nichts, auch kein configure()', () {
      final bridge = _FakeBridge();
      final c = _container(bridge, enabled: false);
      addTearDown(c.dispose);
      expect(c.read(googleConsentProvider), isNull);
      c.read(googleConsentProvider.notifier).set(value: true);
      expect(bridge.calls, isEmpty);
      expect(
        shouldAskGoogleConsent(configured: false, decision: null),
        isFalse,
      );
    });

    test('mit IDs: Standard nicht entschieden, configure() mit IDs', () {
      final bridge = _FakeBridge();
      final c = _container(bridge, enabled: true);
      addTearDown(c.dispose);
      expect(c.read(googleConsentProvider), isNull);
      expect(bridge.calls, <String>['configure:GTM-TEST000:G-TEST000000']);
      expect(shouldAskGoogleConsent(configured: true, decision: null), isTrue);
    });

    test('Zustimmung, Widerruf, Speicher loeschen', () {
      final bridge = _FakeBridge();
      final c = _container(bridge, enabled: true);
      addTearDown(c.dispose);
      c.read(googleConsentProvider);
      c.read(googleConsentProvider.notifier).set(value: true);
      expect(c.read(googleConsentProvider), isTrue);
      c.read(googleConsentProvider.notifier).set(value: false);
      expect(c.read(googleConsentProvider), isFalse);
      c.read(googleConsentProvider.notifier).reset();
      expect(c.read(googleConsentProvider), isNull);
      expect(bridge.calls.skip(1), <String>['grant', 'deny', 'reset']);
    });

    test('gespeicherte Entscheidung wird uebernommen, nicht neu gefragt', () {
      final c = _container(_FakeBridge(false), enabled: true);
      addTearDown(c.dispose);
      expect(c.read(googleConsentProvider), isFalse);
      expect(
        shouldAskGoogleConsent(configured: true, decision: false),
        isFalse,
      );
    });
  });

  test('Einwilligungstext nennt Google, USA, DPF und Zweck (de/en)', () {
    for (final (l10n, purpose) in <(AppLocalizations, String)>[
      (lookupAppLocalizations(const Locale('de')), 'zählen'),
      (lookupAppLocalizations(const Locale('en')), 'count'),
    ]) {
      final text = googleConsentText(l10n);
      expect(text, contains('Google Ireland Limited'));
      expect(text, contains('Google LLC'));
      expect(text, contains('USA'));
      expect(text, contains('Data Privacy Framework'));
      expect(text, contains(purpose));
      expect(text, contains('Google Analytics'));
    }
  });

  group('Rechtstexte', () {
    test('ga4 zaehlt nicht als telemetry', () {
      expect(legalRequirementMet(<String>['telemetry'], {'ga4'}), isFalse);
      expect(legalRequirementMet(<String>['!telemetry'], {'ga4'}), isTrue);
      expect(legalRequirementMet(<String>['ga4'], {'ga4'}), isTrue);
      expect(legalRequirementMet(<String>['ga4'], {'umami'}), isFalse);
    });

    test('Abschnitt Google Analytics in de und en, nur mit ga4', () {
      for (final lang in <String>['de', 'en']) {
        final d = LegalDocument.parse(
          File('assets/legal/$lang/datenschutz.json').readAsStringSync(),
        );
        String all(Set<String> p) =>
            d.visibleFor(p).map((b) => b.text).join('\n');
        expect(all(<String>{}), isNot(contains('Google Analytics')));
        final withGa = all(<String>{'ga4'});
        expect(withGa, contains('Google Analytics'));
        expect(withGa, contains('Data Privacy Framework'));
        expect(withGa, contains('{{GA4_AUFBEWAHRUNG}}'));
      }
    });

    test('Listen-requires: alle Eintraege muessen gelten', () {
      expect(
        legalRequirementMet(<String>['!telemetry', 'ga4'], {'ga4'}),
        isTrue,
      );
      expect(
        legalRequirementMet(<String>['!telemetry', '!ga4'], {'ga4'}),
        isFalse,
      );
      expect(
        legalRequirementMet(<String>['telemetry', 'ga4'], {'umami', 'ga4'}),
        isTrue,
      );
      expect(
        legalRequirementMet(<String>['telemetry', 'ga4'], {'umami'}),
        isFalse,
      );
    });

    test(
      'mit ga4: Kurzfassung, localStorage, Empfaenger, AVV, Speicherdauer',
      () {
        const expected = <String, List<String>>{
          'de': <String>[
            'Nur die Web-Version fragt gesondert',
            'linefm.googleAnalytics',
            'Google Ireland Limited (Google Analytics) als Empfänger',
            'Vertrag zur Auftragsverarbeitung nach Art. 28 DSGVO (Bedingungen',
            'nach 2 Jahren ab',
            'Google-Tag',
            'Der Widerruf gilt für die Zukunft',
          ],
          'en': <String>[
            'Only the web version asks separately',
            'linefm.googleAnalytics',
            'Google Ireland Limited (Google Analytics) becomes an additional',
            'data processing agreement under Art. 28 GDPR with Google Ireland',
            'expire after 2 years',
            'Google tag',
            'Withdrawal applies to the future',
          ],
        };
        for (final lang in <String>['de', 'en']) {
          final d = LegalDocument.parse(
            File('assets/legal/$lang/datenschutz.json').readAsStringSync(),
          );
          String all(Set<String> p) =>
              d.visibleFor(p).map((b) => b.text).join('\n');
          final none = all(<String>{});
          final ga = all(<String>{'ga4'});
          final both = all(<String>{'umami', 'ga4'});
          // Mit GA4 kein pauschales "sendet keine Statistik".
          final noStats = lang == 'de'
              ? 'Diese Version der App sendet keine Statistik'
              : 'This version of the app sends no usage statistics';
          expect(none, contains(noStats));
          expect(ga, isNot(contains(noStats)), reason: lang);
          for (final s in expected[lang]!) {
            expect(ga, contains(s), reason: '$lang: $s');
            expect(none, isNot(contains(s)), reason: '$lang ohne ga4: $s');
          }
          expect(
            both,
            contains(
              lang == 'de'
                  ? 'fragt zusätzlich gesondert'
                  : 'also asks separately',
            ),
          );
          expect(
            d
                .visibleFor(<String>{'ga4'})
                .where((b) => b.url.contains('support.google.com/analytics')),
            isNotEmpty,
          );
        }
      },
    );

    test('GA4_AUFBEWAHRUNG ist nur mit ga4 Pflicht', () {
      final registry =
          (jsonDecode(File('assets/legal/placeholders.json').readAsStringSync())
                  as Map<String, dynamic>)['placeholders']
              as Map<String, dynamic>;
      expect(registry['GA4_AUFBEWAHRUNG'], containsPair('required_if', 'ga4'));
    });
  });
}
