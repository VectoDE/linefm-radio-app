import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/now_playing.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';

/// Live-Daten-Motor: vereint WebSocket, ends_at-Timer und Polling
/// (Spec 3.3). Echte Implementierung: P03; Fake fuer Tests und Stubs.
abstract interface class NowPlayingRepository {
  Stream<List<StationLive>> watchStations();

  Stream<Track?> watchTrack(Station station);

  Stream<List<HistoryEntry>> watchHistory(Station station);

  Stream<int?> watchListeners(Station station);

  Future<void> refresh();

  /// Schliesst WebSocket und Timer.
  void dispose();
}

/// Statische Daten ohne Netzwerk.
class FakeNowPlayingRepository implements NowPlayingRepository {
  FakeNowPlayingRepository({
    Map<String, Track> tracks = const <String, Track>{},
    this.listeners,
    // ignore: prefer_initializing_formals
  }) : _tracks = tracks;

  final Map<String, Track> _tracks;
  final int? listeners;

  @override
  Stream<List<StationLive>> watchStations() =>
      Stream<List<StationLive>>.value(<StationLive>[
        for (final s in stationsCatalog)
          StationLive(station: s, track: _tracks[s.slug]),
      ]);

  @override
  Stream<Track?> watchTrack(Station station) =>
      Stream<Track?>.value(_tracks[station.slug]);

  @override
  Stream<List<HistoryEntry>> watchHistory(Station station) =>
      Stream<List<HistoryEntry>>.value(const <HistoryEntry>[]);

  @override
  Stream<int?> watchListeners(Station station) => Stream<int?>.value(listeners);

  @override
  Future<void> refresh() async {}

  @override
  void dispose() {}
}
