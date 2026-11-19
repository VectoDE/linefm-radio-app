import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/stations/favorite_stations.dart';

/// "Speicher loeschen" (wie `clearAppStorage` der Web-App): entfernt alle
/// lokalen Daten samt Speicher-Bestaetigung und widerruft die Telemetrie-
/// Einwilligung. Danach erscheint der Speicher-Hinweis wieder. Nur
/// "Cover laden: aus" bleibt (Datenschutz-Praeferenz, R3-P03).
///
/// Die laufende Wiedergabe und die gewaehlte Station bleiben unberuehrt.
Future<void> clearAppStorage(WidgetRef ref) async {
  await ref.read(prefsProvider).clearAll();
  await ref.read(telemetryProvider).setConsent(value: false);
  await ref.read(alarmCoordinatorProvider).rescheduleAll(const []);
  ref
    ..invalidate(settingsProvider)
    ..invalidate(favoritesProvider)
    ..invalidate(favoriteStationsProvider)
    ..invalidate(alarmProvider)
    ..invalidate(storageConsentProvider)
    ..invalidate(telemetryConsentProvider);
}
