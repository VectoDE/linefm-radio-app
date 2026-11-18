import 'dart:async';

import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';

/// Vertrag zwischen App-Logik und Audio-Dienst. LinefmAudioHandler (P10)
/// implementiert ihn; Tests und Stubs nutzen [NoopPlaybackService].
abstract interface class PlaybackService {
  PlayerUiState get state;

  Stream<PlayerUiState> get stateStream;

  /// Setzt die Quelle, verbindet und spielt.
  Future<void> playStation(Station station);

  /// Live-Radio: Stop statt Pause, gibt den Stream frei.
  Future<void> stopPlayback();

  /// 0.1 bis 1.0 (Player-Ebene).
  Future<void> setVolume(double volume);

  /// Aktualisiert Benachrichtigung, Sperrbildschirm, Android Auto.
  Future<void> updateNowPlaying(Station station, Track? track);

  Future<void> dispose();
}

/// Spielt nichts, spiegelt aber den Zustand (fuer Stubs und Tests).
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
