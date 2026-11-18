import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_logic.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';

/// Baut den Favoriten fuer einen Titel eines Senders (Zeitstempel aus der
/// injizierten Uhr, Cover-Rueckfall auf das Senderlogo wie die Web-App).
Favorite favoriteForTrack(WidgetRef ref, Station station, Track track) =>
    FavoritesLogic.fromTrack(
      stationSlug: station.slug,
      track: track,
      savedAt: ref.read(clockProvider).now(),
      stationLogoUrl: station.logoUrl,
    );

/// Merkt den Titel oder entfernt ihn wieder (Herz) und meldet
/// `favorite_add` bzw. `favorite_remove` (Spec 2.3, ohne Personenbezug).
void toggleFavoriteWithTelemetry(WidgetRef ref, Favorite favorite) {
  final wasFavorite = FavoritesLogic.contains(
    ref.read(favoritesProvider),
    favorite.key,
  );
  ref.read(favoritesProvider.notifier).toggle(favorite);
  unawaited(
    ref
        .read(telemetryProvider)
        .event(wasFavorite ? 'favorite_remove' : 'favorite_add'),
  );
}

/// Entfernt einen Favoriten (Papierkorb) und meldet `favorite_remove`.
void removeFavoriteWithTelemetry(WidgetRef ref, Favorite favorite) {
  ref.read(favoritesProvider.notifier).remove(favorite.key);
  unawaited(ref.read(telemetryProvider).event('favorite_remove'));
}
