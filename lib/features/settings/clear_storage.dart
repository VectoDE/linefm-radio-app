import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/consent/cast_consent.dart';
import 'package:linefm_radio/features/consent/google_consent.dart';
import 'package:linefm_radio/features/stations/favorite_stations.dart';
import 'package:linefm_radio/ui/widgets/cover_image.dart';

/// "Speicher loeschen" (wie `clearAppStorage` der Web-App): entfernt alle
/// lokalen Daten samt Speicher-Bestaetigung und widerruft die Telemetrie-
/// Einwilligung sowie (Web) die Einwilligung "Reichweitenmessung mit Google". Danach erscheint der Speicher-Hinweis wieder. Nur
/// "Cover laden: aus" bleibt (Datenschutz-Praeferenz).
///
/// Die laufende Wiedergabe und die gewaehlte Station bleiben unberuehrt.
Future<void> clearAppStorage(WidgetRef ref) async {
  // First, so its now empty snapshot is removed with everything else.
  ref.read(nowPlayingRepositoryProvider).forgetRestored();
  await ref.read(prefsProvider).clearAll();
  await CoverImage.diskCache?.clear();
  await ref.read(telemetryProvider).setConsent(value: false);
  await ref.read(alarmCoordinatorProvider).rescheduleAll(const []);
  // Zuletzt: War Google schon geladen, laden web/analytics.js bzw.
  // web/cast.js die Seite neu.
  ref.read(castConsentProvider.notifier).reset();
  ref.read(googleConsentProvider.notifier).reset();
  ref
    ..invalidate(settingsProvider)
    ..invalidate(favoritesProvider)
    ..invalidate(favoriteStationsProvider)
    ..invalidate(alarmProvider)
    ..invalidate(storageConsentProvider)
    ..invalidate(telemetryConsentProvider);
}
