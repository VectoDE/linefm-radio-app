import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';

/// Audio-Handler auf Basis audio_service + just_audio (Spec 2.2, 3.3).
/// Stub: Zustandsverwaltung ohne echte Wiedergabe, ausgebaut in P10.
class LinefmAudioHandler extends BaseAudioHandler implements PlaybackService {
  final PlayerUiState _state = const PlayerUiState();
  final StreamController<PlayerUiState> _controller =
      StreamController<PlayerUiState>.broadcast();

  @override
  PlayerUiState get state => _state;

  @override
  Stream<PlayerUiState> get stateStream => _controller.stream;

  @override
  Future<void> playStation(Station station) async {
    throw UnimplementedError('P10: LinefmAudioHandler.playStation');
  }

  @override
  Future<void> stopPlayback() async {
    throw UnimplementedError('P10: LinefmAudioHandler.stopPlayback');
  }

  @override
  Future<void> setVolume(double volume) async {
    throw UnimplementedError('P10: LinefmAudioHandler.setVolume');
  }

  @override
  Future<void> updateNowPlaying(Station station, Track? track) async {
    throw UnimplementedError('P10: LinefmAudioHandler.updateNowPlaying');
  }

  @override
  Future<void> dispose() => _controller.close();
}
