import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/player_controller.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/services/widgets/home_widget_sync.dart';

import '../support/in_memory_prefs_store.dart';
import '../support/service_doubles.dart';
import 'app_host.dart';

/// Wiedergabe mit steuerbarem Fehler.
class Playback extends NoopPlaybackService {
  final List<String> calls = <String>[];

  List<String> get plays =>
      calls.where((c) => c.startsWith('play:')).toList(growable: false);

  final StreamController<PlayerUiState> _states =
      StreamController<PlayerUiState>.broadcast();
  PlayerUiState _s = const PlayerUiState();

  @override
  PlayerUiState get state => _s;

  @override
  Stream<PlayerUiState> get stateStream => _states.stream;

  void emit(PlayerUiState s) {
    _s = s;
    _states.add(s);
  }

  @override
  Future<void> playStation(Station station) async {
    calls.add('play:${station.slug}');
    emit(_s.copyWith(status: PlayerStatus.connecting, station: station));
    emit(_s.copyWith(status: PlayerStatus.playing));
  }

  @override
  Future<void> stopPlayback() async {
    calls.add('stop');
    emit(_s.copyWith(status: PlayerStatus.idle));
  }

  @override
  Future<void> setVolume(double volume) async {
    calls.add('volume:$volume');
    emit(_s.copyWith(volume: volume));
  }

  @override
  Future<void> updateNowPlaying(Station station, Track? track) async =>
      calls.add('now:${station.slug}:${track?.title}');
}

class Widget implements HomeWidgetSync {
  final List<String> updates = <String>[];

  @override
  Future<void> update({
    Station? station,
    Track? track,
    required bool playing,
  }) async => updates.add('${station?.slug}:${track?.title}:$playing');
}

class Ctx {
  Ctx({
    AppSettings settings = const AppSettings(),
    String? lastStation,
    double? volume,
    bool Function()? activation,
    CastService? cast,
  }) {
    prefs.writeSettings(settings).ignore();
    if (lastStation != null) prefs.writeLastStation(lastStation).ignore();
    if (volume != null) prefs.writeVolume(volume).ignore();
    container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        playbackServiceProvider.overrideWithValue(playback),
        homeWidgetSyncProvider.overrideWithValue(widget),
        if (activation != null)
          userActivationProvider.overrideWithValue(activation),
        if (cast != null) castServiceProvider.overrideWithValue(cast),
        nowPlayingRepositoryProvider.overrideWith((ref) {
          final repo = TestRepository();
          bindNowPlayingRepository(ref, repo);
          return repo;
        }),
        telemetryProvider.overrideWithValue(
          TelemetryHub(
            config: const AppConfig(umamiUrl: 'https://u', umamiWebsiteId: 'x'),
            analytics: <AnalyticsSink>[sink],
            consent: true,
          ),
        ),
      ],
    );
    // Wie die Shell: dauerhaft abonniert, sonst pausiert Riverpod 3 die
    // Provider samt ihrer ref.listen-Abos.
    container
      ..listen(playerControllerProvider, (_, _) {})
      ..listen(nowPlayingRepositoryProvider, (_, _) {});
  }

  final prefs = InMemoryPrefsStore();
  final playback = Playback();
  final widget = Widget();
  final sink = RecordingSink();
  late final ProviderContainer container;

  PlayerController get controller => container.read(playerControllerProvider);
  Station get active => container.read(activeStationProvider);

  void dispose() => container.dispose();
}

Future<void> flush() => Future<void>.delayed(const Duration(milliseconds: 5));

class Cast extends NoopCastService {
  Cast({required this.playing});

  final bool playing;
  int stops = 0;

  @override
  CastState get state => CastState(
    available: true,
    connectedDevice: const CastDevice(id: 'tv', name: 'TV'),
    station: playing ? stationsCatalog.first : null,
  );

  @override
  Future<void> stopMedia() async => stops++;
}
