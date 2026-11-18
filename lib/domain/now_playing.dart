import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';

class NowPlaying {
  const NowPlaying({required this.station, this.track, this.listeners});

  final Station station;
  final Track? track;
  final int? listeners;
}

/// Sender plus Ticker-Titel fuer die Stationsliste (stationsProvider).
class StationLive {
  const StationLive({required this.station, this.track});

  final Station station;
  final Track? track;
}
