import 'dart:async';

import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';

const CastDevice tv = CastDevice(id: 'tv', name: 'Wohnzimmer');
const CastDevice speaker = CastDevice(id: 'sp', name: 'Küche');

/// Fake-Sitzung: ersetzt das Plugin.
class FakeCastBackend implements CastBackend {
  final StreamController<List<CastDevice>> _devices =
      StreamController<List<CastDevice>>.broadcast(sync: true);
  final StreamController<CastLinkState> _links =
      StreamController<CastLinkState>.broadcast(sync: true);
  List<CastDevice> _list = <CastDevice>[];
  CastLinkState _link = CastLinkState.none;

  final List<CastMedia> loads = <CastMedia>[];
  final List<double> volumes = <double>[];
  final List<bool> scans = <bool>[];
  int endCalls = 0;
  bool startResult = true;
  Completer<void>? loadGate;

  void setDevices(List<CastDevice> list) {
    _list = list;
    _devices.add(list);
  }

  void setLink(CastLinkState link) {
    _link = link;
    _links.add(link);
  }

  @override
  List<CastDevice> get devices => _list;

  @override
  Stream<List<CastDevice>> get devicesStream => _devices.stream;

  @override
  CastLinkState get link => _link;

  @override
  Stream<CastLinkState> get linkStream => _links.stream;

  @override
  Future<void> startDiscovery({bool activeScan = false}) async =>
      scans.add(activeScan);

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<bool> startSession(CastDevice device) async {
    if (startResult) {
      setLink(const CastLinkState(CastLink.connecting, tv));
      setLink(CastLinkState(CastLink.connected, device));
    }
    return startResult;
  }

  @override
  Future<void> endSession() async {
    endCalls++;
    setLink(CastLinkState.none);
  }

  @override
  Future<void> load(CastMedia media) async {
    final gate = loadGate;
    if (gate != null) await gate.future;
    loads.add(media);
  }

  int stopMediaCalls = 0;

  @override
  Future<void> stopMedia() async => stopMediaCalls++;

  @override
  void setVolume(double volume) => volumes.add(volume);

  @override
  Future<void> dispose() async {}
}

Future<Uri> url(Station s) async =>
    Uri.parse('https://stream.laut.fm/${s.slug}');

const Track a = Track(
  artist: 'Artist A',
  title: 'Song A',
  artworkUrl: 'https://cdn.example/a.jpg',
);
const Track b = Track(artist: 'Artist B', title: 'Song B');

Future<void> settle() => Future<void>.delayed(Duration.zero);
