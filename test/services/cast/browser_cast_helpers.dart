import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/services/cast/browser_cast.dart';

/// Fake for web/cast.js: no real Google script, no real Cast device.
class FakeBrowserCastBridge implements BrowserCastBridge {
  FakeBrowserCastBridge({this.supported = true, this.decision});

  @override
  bool supported;

  @override
  bool? decision;

  final List<void Function()> _listeners = <void Function()>[];
  int sdkLoads = 0;
  bool sdkResult = true;
  int sessionRequests = 0;
  int sessionEnds = 0;
  int stops = 0;
  int resets = 0;
  final List<Map<String, String?>> loads = <Map<String, String?>>[];
  final List<double> volumes = <double>[];

  String state = '';
  String id = '';
  String name = '';

  void emit(String next, {String device = '', String label = ''}) {
    state = next;
    name = device;
    id = label;
    for (final l in List<void Function()>.of(_listeners)) {
      l();
    }
  }

  @override
  void grant() => decision = true;

  @override
  void deny() => decision = false;

  @override
  void reset() {
    resets++;
    decision = null;
  }

  @override
  Future<bool> loadSdk() async {
    sdkLoads++;
    if (sdkResult) state = 'NOT_CONNECTED';
    return sdkResult;
  }

  @override
  void onChange(void Function() listener) => _listeners.add(listener);

  @override
  String get castState => state;

  @override
  String get deviceId => id;

  @override
  String get deviceName => name;

  @override
  Future<bool> requestSession() async {
    sessionRequests++;
    emit('CONNECTED', device: 'Wohnzimmer TV', label: 'abc');
    return true;
  }

  @override
  void endSession() {
    sessionEnds++;
    emit('NOT_CONNECTED');
  }

  @override
  Future<bool> loadMedia({
    required String url,
    required String contentType,
    required String title,
    required String artist,
    required String album,
    String? imageUrl,
  }) async {
    loads.add(<String, String?>{
      'url': url,
      'type': contentType,
      'title': title,
      'artist': artist,
      'album': album,
      'image': imageUrl,
    });
    return true;
  }

  @override
  Future<void> stopMedia() async => stops++;

  @override
  void setVolume(double volume) => volumes.add(volume);
}

Future<void> settle() => Future<void>.delayed(Duration.zero);
