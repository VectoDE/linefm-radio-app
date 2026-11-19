import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_backend_stub.dart'
    if (dart.library.io) 'package:linefm_radio/services/cast/cast_backend_plugin.dart';

class CastDevice {
  const CastDevice({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) => other is CastDevice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class CastState {
  const CastState({
    this.available = false,
    this.devices = const <CastDevice>[],
    this.connectedDevice,
    this.connecting = false,
    this.station,
  });

  /// false auf Plattformen ohne Cast und ohne Google Play Services.
  final bool available;
  final List<CastDevice> devices;
  final CastDevice? connectedDevice;

  /// Sitzung wird gerade aufgebaut.
  final bool connecting;

  /// Sender, der gerade auf dem Gerät läuft (übergeben und nicht gestoppt).
  final Station? station;

  bool get isCasting => connectedDevice != null;

  /// Auf dem Gerät läuft ein Sender (Player zeigt „Stop“).
  bool get isPlayingMedia => isCasting && station != null;

  @override
  bool operator ==(Object other) =>
      other is CastState &&
      other.available == available &&
      other.connectedDevice == connectedDevice &&
      other.connecting == connecting &&
      other.station == station &&
      _sameDevices(other.devices, devices);

  @override
  int get hashCode => Object.hash(
    available,
    connectedDevice,
    connecting,
    station,
    devices.length,
  );

  static bool _sameDevices(List<CastDevice> a, List<CastDevice> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i] || a[i].name != b[i].name) return false;
    }
    return true;
  }
}

/// Chromecast (Spec 2.2). Implementierung: `ChromeCastService`.
abstract interface class CastService {
  CastState get state;

  /// Liefert beim Abonnieren zuerst den aktuellen Zustand.
  Stream<CastState> get states;

  /// [activeScan]: aktive Suche, solange der Geräte-Dialog offen ist.
  Future<void> startDiscovery({bool activeScan = false});

  Future<void> stopDiscovery();

  /// Baut die Sitzung zum Gerät auf. Die Übergabe der Wiedergabe löst der
  /// Zustandswechsel aus (siehe `CastHandoff`).
  Future<void> connect(CastDevice device);

  Future<void> disconnect();

  /// Übergibt den Stream an die Cast-Sitzung.
  Future<void> cast(Station station, Track? track);

  /// Zieht Titel/Künstler/Cover nach (Titelwechsel), ohne den Sender zu
  /// wechseln.
  Future<void> updateTrack(Station station, Track? track);

  /// Stoppt die Wiedergabe auf dem Gerät; die Sitzung bleibt bestehen.
  Future<void> stopMedia();

  /// Lautstärke des Cast-Geräts, 0.0 bis 1.0.
  Future<void> setVolume(double volume);

  Future<void> dispose();
}

class NoopCastService implements CastService {
  const NoopCastService();

  @override
  CastState get state => const CastState();

  @override
  Stream<CastState> get states => Stream<CastState>.value(const CastState());

  @override
  Future<void> startDiscovery({bool activeScan = false}) async {}

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<void> connect(CastDevice device) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> cast(Station station, Track? track) async {}

  @override
  Future<void> updateTrack(Station station, Track? track) async {}

  @override
  Future<void> stopMedia() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> dispose() async {}
}

/// Startet das Cast-SDK, erst beim ersten Tippen auf den Cast-Knopf (L4),
/// nicht beim App-Start: Vorher sendet das SDK nichts an Google. Ohne
/// Cast-Unterstützung (Web, Desktop, fehlende Google Play Services) bleibt
/// [castBackend] `null`. Mehrfachaufrufe teilen sich einen Start.
Future<void> initCast() => _castInit ??= () async {
  castBackend = await castBackendFactory();
}();

/// Erzeugt das Backend beim ersten Tippen; Tests setzen ein Fake.
@visibleForTesting
Future<CastBackend?> Function() castBackendFactory = createPluginBackend;

Future<void>? _castInit;

/// Android und iOS (nicht Web): Plattformen, auf denen Cast gehen kann.
bool castPlatformSupported() =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Nur fuer Tests: Start-Zustand zuruecksetzen.
@visibleForTesting
void resetCastInitForTest() => _castInit = null;
