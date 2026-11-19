import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/features/consent/consent_dialog.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final de = lookupAppLocalizations(const Locale('de'));
  final en = lookupAppLocalizations(const Locale('en'));

  const umami = AppConfig(umamiUrl: 'https://u.example', umamiWebsiteId: 'x');
  const sentry = AppConfig(sentryDsn: 'https://k@s.example/1');
  const firebase = AppConfig(firebaseEnabled: true);

  test('nennt nur die aktiven Anbieter (R3-P05)', () {
    final text = telemetryConsentText(de, umami);
    expect(text, contains('Umami'));
    expect(text, isNot(contains('GlitchTip')));
    expect(text, isNot(contains('Google')));
    expect(text, isNot(contains('USA')));
    expect(text, contains('IP-Adresse'));
    expect(text, contains('freiwillig'));
  });

  test('Sentry allein: nur Fehlerberichte', () {
    final text = telemetryConsentText(de, sentry);
    expect(text, contains('GlitchTip bzw. Sentry'));
    expect(text, isNot(contains('Umami')));
  });

  test('Firebase: Google, USA-Uebermittlung und DPF', () {
    for (final l10n in <AppLocalizations>[de, en]) {
      final text = telemetryConsentText(l10n, firebase);
      expect(text, contains('Google'));
      expect(text, contains('USA'));
      expect(text, contains('Data Privacy Framework'));
      expect(text, isNot(contains('Umami')));
    }
  });

  test('alle drei Anbieter in einer Liste', () {
    final text = telemetryConsentText(
      en,
      umami.copyWith(sentryDsn: 'https://k@s.example/1', firebaseEnabled: true),
    );
    expect(
      text,
      contains(
        'Umami (usage statistics), GlitchTip or Sentry (error reports), '
        'Google (Firebase Analytics and Crashlytics)',
      ),
    );
  });

  group('Firebase nur auf unterstuetzten Plattformen (R4-S05)', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    for (final platform in <TargetPlatform>[
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      test('${platform.name}: keine Google- oder USA-Angaben', () {
        debugDefaultTargetPlatformOverride = platform;
        final config = umami.copyWith(firebaseEnabled: true);
        expect(config.firebaseConfigured, isFalse);
        expect(activeLegalProviders(config), <String>{'umami'});
        for (final l10n in <AppLocalizations>[de, en]) {
          final text = telemetryConsentText(l10n, config);
          expect(text, isNot(contains('Google')));
          expect(text, isNot(contains('USA')));
        }
        // Nur Firebase gesetzt: gar keine Telemetrie, kein Dialog.
        expect(firebase.telemetryConfigured, isFalse);
      });
    }

    for (final platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    ]) {
      test('${platform.name}: Firebase aktiv', () {
        debugDefaultTargetPlatformOverride = platform;
        expect(firebase.firebaseConfigured, isTrue);
        expect(activeLegalProviders(firebase), contains('firebase'));
      });
    }

    test('gleiche Plattformliste wie packages/linefm_firebase', () {
      final source = File('packages/linefm_firebase/lib/linefm_firebase.dart')
          .readAsStringSync();
      final getter = RegExp(r'static bool get supported =>([^;]*);')
          .firstMatch(source)!
          .group(1)!;
      final platforms = RegExp(r'TargetPlatform\.(\w+)')
          .allMatches(getter)
          .map((m) => m.group(1))
          .toSet();
      expect(getter, contains('kIsWeb'));
      expect(platforms, <String>{'android', 'iOS', 'macOS'});
    });
  });
}
