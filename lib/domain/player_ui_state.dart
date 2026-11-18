import 'package:linefm_radio/domain/station.dart';

enum PlayerStatus { idle, connecting, playing, reconnecting, error }

class PlayerUiState {
  const PlayerUiState({
    this.status = PlayerStatus.idle,
    this.station,
    this.volume = 1.0,
  });

  final PlayerStatus status;
  final Station? station;

  /// 0.1 bis 1.0 in 10 Stufen (Player-Ebene, Spec 3.3).
  final double volume;

  bool get isPlaying => status == PlayerStatus.playing;
  bool get isBusy =>
      status == PlayerStatus.connecting || status == PlayerStatus.reconnecting;

  PlayerUiState copyWith({
    PlayerStatus? status,
    Station? station,
    double? volume,
  }) => PlayerUiState(
    status: status ?? this.status,
    station: station ?? this.station,
    volume: volume ?? this.volume,
  );

  @override
  bool operator ==(Object other) =>
      other is PlayerUiState &&
      other.status == status &&
      other.station == station &&
      other.volume == volume;

  @override
  int get hashCode => Object.hash(status, station, volume);
}
