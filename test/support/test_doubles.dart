// Test doubles for the data layer. They live under test/ so that no fake or
// stub ships in the app; production wiring comes from productionOverrides().

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/data/api/song_change_socket.dart';
import 'package:linefm_radio/data/live/now_playing_repository.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/now_playing.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';

/// Clock that only moves when the test says so.
class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);

  void setTo(DateTime t) => _now = t;
}

/// laut.fm API without network access.
class StubLautApi implements LautApi {
  const StubLautApi();

  @override
  Future<Track?> currentSong(String slug) async => null;

  @override
  Future<List<Track>> lastSongs(String slug) async => const <Track>[];

  @override
  Future<int?> listeners(String slug) async => null;

  @override
  Future<String?> streamUrl(String slug) async => null;
}

/// Song-change socket that never emits.
class StubSongChangeSocket implements SongChangeSocket {
  const StubSongChangeSocket();

  @override
  Stream<SongChange> get changes => const Stream<SongChange>.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> close() async {}
}

/// Static now-playing data without network.
class FakeNowPlayingRepository implements NowPlayingRepository {
  FakeNowPlayingRepository({
    Map<String, Track> tracks = const <String, Track>{},
    this.history = const <HistoryEntry>[],
    this.listeners,
    // ignore: prefer_initializing_formals
  }) : _tracks = tracks;

  final Map<String, Track> _tracks;
  final List<HistoryEntry> history;
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
      Stream<List<HistoryEntry>>.value(history);

  @override
  Stream<int?> watchListeners(Station station) => Stream<int?>.value(listeners);

  @override
  Stream<bool> watchOnline() => Stream<bool>.value(true);

  @override
  void setActiveStation(Station station) {}

  @override
  void setForeground({required bool value}) {}

  @override
  void setPlaying({required bool value}) {}

  @override
  Future<void> refresh() async {}

  @override
  void dispose() {}
}

/// Offline data layer for widget and provider tests: stub API and an empty
/// [FakeNowPlayingRepository] bound to the app like the live one.
List<Override> offlineDataOverrides({NowPlayingRepository? repository}) =>
    <Override>[
      lautApiProvider.overrideWithValue(const StubLautApi()),
      nowPlayingRepositoryProvider.overrideWith((ref) {
        final repo = repository ?? FakeNowPlayingRepository();
        bindNowPlayingRepository(ref, repo);
        return repo;
      }),
    ];
