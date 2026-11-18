import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';

class NowPlaying {
  const NowPlaying({required this.station, this.track, this.listeners});

  final Station station;
  final Track? track;
  final int? listeners;

  NowPlaying copyWith({Station? station, Track? track, int? listeners}) =>
      NowPlaying(
        station: station ?? this.station,
        track: track ?? this.track,
        listeners: listeners ?? this.listeners,
      );

  @override
  bool operator ==(Object other) =>
      other is NowPlaying &&
      other.station == station &&
      other.track == track &&
      other.listeners == listeners;

  @override
  int get hashCode => Object.hash(station, track, listeners);
}

/// Sender plus Ticker-Titel fuer die Stationsliste (stationsProvider).
class StationLive {
  const StationLive({required this.station, this.track});

  final Station station;
  final Track? track;

  StationLive copyWith({Station? station, Track? track}) =>
      StationLive(station: station ?? this.station, track: track ?? this.track);

  @override
  bool operator ==(Object other) =>
      other is StationLive && other.station == station && other.track == track;

  @override
  int get hashCode => Object.hash(station, track);
}
