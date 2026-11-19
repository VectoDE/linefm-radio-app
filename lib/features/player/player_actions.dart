import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/favorites/favorites_logic.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';

// Hoerdauer-Klassen gehoeren zur Telemetrie im PlayerController.
export 'package:linefm_radio/app/player_controller.dart' show secondsBucket;

/// Der Sender vor oder nach [current] im Katalog, rundum (Wisch-Geste und
/// Tastatur im Player).
Station neighborStation(Station current, int delta) {
  final index = stationsCatalog.indexOf(current);
  // Dart liefert bei positivem Teiler nie ein negatives Modulo.
  return stationsCatalog[((index < 0 ? 0 : index) + delta) %
      stationsCatalog.length];
}

/// Aktionen des Player-Screens: ruft den [PlayerController] und die Dienste
/// auf und meldet die Telemetrie-Ereignisse aus Spec 2.3 (`shuffle`,
/// `favorite_add`, `favorite_remove`, `share_song`). `play`, `stop` und
/// `error_stream` meldet der PlayerController an einer Stelle.
///
/// Die Ereignisse tragen nur Sender-Kennung und grobe Klassen, nie Titel,
/// Kuenstler oder Geraetedaten. Ohne Einwilligung verwirft der Hub sie.
class PlayerActions {
  PlayerActions(this._ref);

  final Ref _ref;

  void _event(String name, [Map<String, Object> props = const {}]) {
    _ref.read(telemetryProvider).event(name, props).ignore();
  }

  /// Play/Stop-Knopf.
  Future<void> togglePlayback() =>
      _ref.read(playerControllerProvider).togglePlayback();

  /// Zufaellige andere Station abspielen (Web-App-Verhalten).
  Future<void> shuffle() async {
    _event('shuffle');
    await _ref.read(playerControllerProvider).shuffleStation();
  }

  /// Naechster (+1) oder vorheriger (-1) Sender. Laeuft die Wiedergabe oder
  /// verbindet sie gerade, wird der neue Sender abgespielt, sonst nur
  /// gewaehlt.
  Future<void> stepStation(int delta) async {
    final controller = _ref.read(playerControllerProvider);
    final next = neighborStation(_ref.read(activeStationProvider), delta);
    final state = _ref.read(playbackServiceProvider).state;
    if (state.isPlaying || state.isBusy) {
      await controller.startStation(next);
    } else {
      await controller.selectStation(next);
    }
  }

  /// Wiederholt den Start nach einem Fehler.
  Future<void> retry() => _ref
      .read(playerControllerProvider)
      .startStation(_ref.read(activeStationProvider));

  /// Herz: Song merken oder wieder entfernen.
  void toggleFavorite(Station station, Track track) {
    final favorite = FavoritesLogic.fromTrack(
      stationSlug: station.slug,
      track: track,
      savedAt: _ref.read(clockProvider).now(),
      stationLogoUrl: station.logoUrl,
    );
    final saved = FavoritesLogic.contains(
      _ref.read(favoritesProvider),
      favorite.key,
    );
    _ref.read(favoritesProvider.notifier).toggle(favorite);
    _event(saved ? 'favorite_remove' : 'favorite_add');
  }

  Future<void> shareSong(Station station, Track track) {
    _event('share_song');
    return _ref.read(shareServiceProvider).shareSong(station, track);
  }

  Future<void> openUrl(Uri uri) => _ref.read(shareServiceProvider).openUrl(uri);

  /// Apple-Music-Link des laufenden Titels (aus dem iTunes-Treffer), sonst
  /// `null`.
  Future<Uri?> appleMusicUri(Track track) async {
    final result = await _ref
        .read(artworkProvider)
        .lookup(track, priority: true);
    final url = result?.trackViewUrl;
    return url == null ? null : Uri.tryParse(url);
  }
}

final playerActionsProvider = Provider<PlayerActions>(PlayerActions.new);
