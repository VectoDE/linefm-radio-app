import 'dart:async';

import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';

/// Vertrag zwischen App-Logik und Audio-Dienst. LinefmAudioHandler
/// implementiert ihn; Tests nutzen einen Double aus test/support.
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
