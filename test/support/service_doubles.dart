// Service doubles for tests. They live under test/ so that no stub ships in
// the app; production wiring comes from productionOverrides().

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/data/artwork/itunes_artwork.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/share/share_service.dart';
import 'package:linefm_radio/services/sleep_timer/sleep_timer_service.dart';
import 'package:linefm_radio/services/widgets/home_widget_sync.dart';

/// Plays nothing but mirrors the state.
class NoopPlaybackService implements PlaybackService {
  NoopPlaybackService();

  PlayerUiState _state = const PlayerUiState();
  final StreamController<PlayerUiState> _controller =
      StreamController<PlayerUiState>.broadcast();

  @override
  PlayerUiState get state => _state;

  @override
  Stream<PlayerUiState> get stateStream => _controller.stream;

  void _emit(PlayerUiState s) {
    _state = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  @override
  Future<void> playStation(Station station) async =>
      _emit(_state.copyWith(status: PlayerStatus.playing, station: station));

  @override
  Future<void> stopPlayback() async =>
      _emit(_state.copyWith(status: PlayerStatus.idle));

  @override
  Future<void> setVolume(double volume) async =>
      _emit(_state.copyWith(volume: volume));

  @override
  Future<void> updateNowPlaying(Station station, Track? track) async {}

  @override
  Future<void> dispose() => _controller.close();
}

class NoopShareService implements ShareService {
  const NoopShareService();

  @override
  Future<void> shareSong(Station station, Track track) async {}

  @override
  Future<void> shareText(String text) async {}

  @override
  Future<void> exportFavorites(
    List<Favorite> favorites,
    ExportFormat format,
  ) async {}

  @override
  Future<void> openUrl(Uri uri) async {}
}

class NoopSleepTimerService implements SleepTimerService {
  const NoopSleepTimerService();

  @override
  SleepTimerState get state => const SleepTimerState();

  @override
  Stream<SleepTimerState> get states =>
      Stream<SleepTimerState>.value(const SleepTimerState());

  @override
  Future<void> start(SleepTimerMode mode, {Track? currentTrack}) async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

class NoopAlarmCoordinator implements AlarmCoordinator {
  const NoopAlarmCoordinator();

  static final ValueNotifier<AlarmRinging?> _none =
      ValueNotifier<AlarmRinging?>(null);

  @override
  ValueListenable<AlarmRinging?> get ringing => _none;

  @override
  Future<void> rescheduleAll(List<AlarmRule> rules) async {}

  @override
  Future<void> snooze(String ruleId) async {}

  @override
  Future<void> dismiss(String ruleId) async {}
}

/// Silent platform services for every provider that production wires in
/// main() and that has no safe default in the app. A provider can only be
/// overridden once per container, so pass `false` for each one the test
/// overrides itself.
List<Override> noopServiceOverrides({
  bool playback = true,
  bool share = true,
  bool sleepTimer = true,
  bool alarm = true,
  bool cast = true,
  bool homeWidget = true,
  bool artwork = true,
}) => <Override>[
  if (playback)
    playbackServiceProvider.overrideWith((ref) {
      final service = NoopPlaybackService();
      ref.onDispose(service.dispose);
      return service;
    }),
  if (share) shareServiceProvider.overrideWithValue(const NoopShareService()),
  if (sleepTimer)
    sleepTimerServiceProvider.overrideWithValue(const NoopSleepTimerService()),
  if (alarm)
    alarmCoordinatorProvider.overrideWithValue(const NoopAlarmCoordinator()),
  if (cast) castServiceProvider.overrideWithValue(const NoopCastService()),
  if (homeWidget)
    homeWidgetSyncProvider.overrideWithValue(const NoopHomeWidgetSync()),
  if (artwork) artworkProvider.overrideWithValue(const NoopArtworkService()),
];
