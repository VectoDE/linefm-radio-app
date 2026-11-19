import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/features/consent/consent_dialog.dart';
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
}
