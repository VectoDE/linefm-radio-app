import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';

/// Brueke zum nativen CarPlay-Code, MethodChannel de.linefm.app/carplay
/// (Methoden getStations, play, Rueckkanal nowPlaying). Besitzer: P17.
abstract interface class CarPlayBridge {
  static const String channelName = 'de.linefm.app/carplay';

  Future<void> init();

  Future<void> updateNowPlaying(Station station, Track? track);
}

class NoopCarPlayBridge implements CarPlayBridge {
  const NoopCarPlayBridge();

  @override
  Future<void> init() async {}

  @override
  Future<void> updateNowPlaying(Station station, Track? track) async {}
}
