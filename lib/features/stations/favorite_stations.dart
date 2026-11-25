import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/app/stations_provider.dart';
import 'package:linefm_radio/domain/favorites/favorite_stations_logic.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/services/audio/audio_handler.dart';

/// Favoriten-Sender: per Stern auf der Stationskarte gemerkte
/// Sender, getrennt von den Song-Favoriten ([favoritesProvider]).
///
/// - Gespeichert wird ueber den [PrefsStore] unter eigenem Schluessel und
///   damit nach der Speicher-Hinweis-Regel: ohne Bestaetigung bleibt die
///   Auswahl nur bis zum Beenden der App, "Speicher loeschen" leert sie.
/// - Jede Aenderung geht an den Audio-Dienst, damit Android Auto den Ordner
///   "Favoriten-Sender" aktuell zeigt.
class FavoriteStationsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final slugs = ref.read(prefsProvider).readFavoriteStations();
    _publish(slugs);
    return slugs;
  }

  bool isFavorite(Station station) =>
      FavoriteStationsLogic.contains(state, station);

  /// Merkt [station] oder entfernt sie wieder.
  void toggle(Station station) {
    state = FavoriteStationsLogic.toggle(state, station);
    _publish(state);
    ref.read(prefsProvider).writeFavoriteStations(state).ignore();
  }

  void _publish(Set<String> slugs) {
    final service = ref.read(playbackServiceProvider);
    if (service is LinefmAudioHandler) service.favoriteStationSlugs = slugs;
  }
}

final favoriteStationsProvider =
    NotifierProvider<FavoriteStationsNotifier, Set<String>>(
      FavoriteStationsNotifier.new,
    );

/// Gemerkte Sender in der Reihenfolge der Senderliste.
final favoriteStationListProvider = Provider<List<Station>>(
  (ref) => FavoriteStationsLogic.stations(
    ref.watch(favoriteStationsProvider),
    catalog: ref.watch(stationsCatalogProvider),
  ),
);
