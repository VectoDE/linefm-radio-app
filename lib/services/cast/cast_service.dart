import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';

class CastDevice {
  const CastDevice({required this.id, required this.name});

  final String id;
  final String name;
}

class CastState {
  const CastState({
    this.available = false,
    this.devices = const <CastDevice>[],
    this.connectedDevice,
  });

  /// false auf Plattformen ohne Cast und ohne Google Play Services.
  final bool available;
  final List<CastDevice> devices;
  final CastDevice? connectedDevice;

  bool get isCasting => connectedDevice != null;
}

/// Chromecast (Spec 2.2). Implementierung: P19.
abstract interface class CastService {
  CastState get state;

  Stream<CastState> get states;

  Future<void> startDiscovery();

  Future<void> stopDiscovery();

  Future<void> connect(CastDevice device);

  Future<void> disconnect();

  /// Uebergibt den Stream an die Cast-Sitzung.
  Future<void> cast(Station station, Track? track);

  Future<void> dispose();
}

class NoopCastService implements CastService {
  const NoopCastService();

  @override
  CastState get state => const CastState();

  @override
  Stream<CastState> get states => Stream<CastState>.value(const CastState());

  @override
  Future<void> startDiscovery() async {}

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<void> connect(CastDevice device) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> cast(Station station, Track? track) async {}

  @override
  Future<void> dispose() async {}
}

/// Initialisiert Cast (No-Op bis P19).
Future<void> initCast() async {}
