import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/favorites/favorites_logic.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';

/// Grobe Klasse fuer die Hoerdauer beim Stop-Ereignis (keine genauen Werte,
/// Datensparsamkeit, Spec 2.3).
String secondsBucket(int seconds) {
  if (seconds < 10) return '<10';
  if (seconds < 60) return '10-59';
  if (seconds < 300) return '60-299';
  if (seconds < 900) return '300-899';
  if (seconds < 1800) return '900-1799';
  if (seconds < 3600) return '1800-3599';
  return '3600+';
}

/// Der Sender vor oder nach [current] im Katalog, rundum (Wisch-Geste und
/// Tastatur im Player).
Station neighborStation(Station current, int delta) {
  final index = stationsCatalog.indexOf(current);
  // Dart liefert bei positivem Teiler nie ein negatives Modulo.
  return stationsCatalog[((index < 0 ? 0 : index) + delta) %
      stationsCatalog.length];
}

/// Aktionen des Player-Screens: ruft den [PlayerController] und die Dienste
/// auf und meldet die Telemetrie-Ereignisse aus Spec 2.3 (`play`, `stop`,
/// `shuffle`, `favorite_add`, `favorite_remove`, `share_song`).
///
/// Die Ereignisse tragen nur Sender-Kennung und grobe Klassen, nie Titel,
/// Kuenstler oder Geraetedaten. Ohne Einwilligung verwirft der Hub sie.
class PlayerActions {
  PlayerActions(this._ref);

  final Ref _ref;

  DateTime? _playStartedAt;

  void _event(String name, [Map<String, Object> props = const {}]) {
    _ref.read(telemetryProvider).event(name, props).ignore();
  }

  /// Play/Stop-Knopf.
  Future<void> togglePlayback() async {
    final state = _ref.read(playbackServiceProvider).state;
    final station = _ref.read(activeStationProvider);
    if (state.isPlaying || state.isBusy) {
      final started = _playStartedAt;
      _playStartedAt = null;
      _event('stop', <String, Object>{
        'station': station.slug,
        if (started != null)
          'seconds_bucket': secondsBucket(
            _ref.read(clockProvider).now().difference(started).inSeconds,
          ),
      });
    } else {
      _playStartedAt = _ref.read(clockProvider).now();
      _event('play', <String, Object>{'station': station.slug});
    }
    await _ref.read(playerControllerProvider).togglePlayback();
  }

  /// Zufaellige andere Station abspielen (Web-App-Verhalten).
  Future<void> shuffle() async {
    _event('shuffle');
    _playStartedAt = _ref.read(clockProvider).now();
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
      _playStartedAt = _ref.read(clockProvider).now();
      _event('play', <String, Object>{'station': next.slug});
      await controller.startStation(next);
    } else {
      await controller.selectStation(next);
    }
  }

  /// Wiederholt den Start nach einem Fehler.
  Future<void> retry() async {
    final station = _ref.read(activeStationProvider);
    _playStartedAt = _ref.read(clockProvider).now();
    _event('play', <String, Object>{'station': station.slug});
    await _ref.read(playerControllerProvider).startStation(station);
  }

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
