import 'dart:async';

import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';

/// Interface to `window.linefmCast` (web/cast.js): consent and the Google Cast
/// web sender. The decision lives in the browser's localStorage (key
/// `linefm.googleCast`), like the Google Analytics consent: it applies to the
/// web version only and must be known before anything loads from Google.
abstract interface class BrowserCastBridge {
  /// Browser can cast at all (Chromium on desktop or Android).
  bool get supported;

  /// `true` = allowed, `false` = declined, `null` = not decided yet.
  bool? get decision;

  void grant();

  /// Declines. If the Cast script was already loaded, the page reloads.
  void deny();

  /// Forgets the decision (clear storage). Reloads like [deny].
  void reset();

  /// Loads the Google Cast sender script, only after [grant]. `false` if not
  /// allowed, not supported or the script failed.
  Future<bool> loadSdk();

  /// Called on every cast or session state change of the SDK.
  void onChange(void Function() listener);

  /// `NO_DEVICES_AVAILABLE`, `NOT_CONNECTED`, `CONNECTING`, `CONNECTED`, or
  /// empty before [loadSdk].
  String get castState;

  String get deviceId;

  String get deviceName;

  /// Opens the browser's device picker; `true` once a session started.
  Future<bool> requestSession();

  void endSession();

  Future<bool> loadMedia({
    required String url,
    required String contentType,
    required String title,
    required String artist,
    required String album,
    String? imageUrl,
  });

  Future<void> stopMedia();

  void setVolume(double volume);
}

/// No effect (tests, other platforms, page without cast.js).
class NoopBrowserCastBridge implements BrowserCastBridge {
  const NoopBrowserCastBridge();

  @override
  bool get supported => false;

  @override
  bool? get decision => null;

  @override
  void grant() {}

  @override
  void deny() {}

  @override
  void reset() {}

  @override
  Future<bool> loadSdk() async => false;

  @override
  void onChange(void Function() listener) {}

  @override
  String get castState => '';

  @override
  String get deviceId => '';

  @override
  String get deviceName => '';

  @override
  Future<bool> requestSession() async => false;

  @override
  void endSession() {}

  @override
  Future<bool> loadMedia({
    required String url,
    required String contentType,
    required String title,
    required String artist,
    required String album,
    String? imageUrl,
  }) async => false;

  @override
  Future<void> stopMedia() async {}

  @override
  void setVolume(double volume) {}
}

/// Placeholder device in the web version: the browser shows its own device
/// picker, so the app never sees a device list. Present while the SDK reports
/// devices in reach.
const String browserPickerDeviceId = 'browser-cast-picker';

const CastDevice browserPickerDevice = CastDevice(
  id: browserPickerDeviceId,
  name: '',
);

/// [CastBackend] for the web version on top of [BrowserCastBridge] (Default
/// Media Receiver). Discovery is up to the browser; [startSession] opens its
/// picker.
class BrowserCastBackend implements CastBackend {
  BrowserCastBackend(this._bridge) {
    _bridge.onChange(_update);
    _snapshot();
  }

  final BrowserCastBridge _bridge;
  final StreamController<List<CastDevice>> _devices =
      StreamController<List<CastDevice>>.broadcast();
  final StreamController<CastLinkState> _links =
      StreamController<CastLinkState>.broadcast();

  List<CastDevice> _list = const <CastDevice>[];
  CastLinkState _link = CastLinkState.none;
  bool _closed = false;

  void _snapshot() {
    final state = _bridge.castState;
    _list = switch (state) {
      'NOT_CONNECTED' ||
      'CONNECTING' ||
      'CONNECTED' => const <CastDevice>[browserPickerDevice],
      _ => const <CastDevice>[],
    };
    _link = switch (state) {
      'CONNECTED' => CastLinkState(CastLink.connected, _device()),
      'CONNECTING' => const CastLinkState(
        CastLink.connecting,
        browserPickerDevice,
      ),
      _ => CastLinkState.none,
    };
  }

  CastDevice _device() {
    final id = _bridge.deviceId;
    final name = _bridge.deviceName;
    return CastDevice(
      id: id.isEmpty ? browserPickerDeviceId : id,
      name: name.isEmpty ? 'Chromecast' : name,
    );
  }

  void _update() {
    if (_closed) return;
    final devices = _list;
    final link = _link;
    _snapshot();
    if (!_sameIds(devices, _list)) _devices.add(_list);
    if (link != _link || link.device?.name != _link.device?.name) {
      _links.add(_link);
    }
  }

  static bool _sameIds(List<CastDevice> a, List<CastDevice> b) =>
      a.length == b.length &&
      Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);

  @override
  List<CastDevice> get devices => _list;

  @override
  Stream<List<CastDevice>> get devicesStream => _devices.stream;

  @override
  CastLinkState get link => _link;

  @override
  Stream<CastLinkState> get linkStream => _links.stream;

  @override
  Future<void> startDiscovery({bool activeScan = false}) async {}

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<bool> startSession(CastDevice device) async {
    final ok = await _bridge.requestSession();
    _update();
    return ok;
  }

  @override
  Future<void> endSession() async {
    _bridge.endSession();
    _update();
  }

  @override
  Future<void> load(CastMedia media) async {
    final ok = await _bridge.loadMedia(
      url: media.streamUrl.toString(),
      contentType: 'audio/mpeg',
      title: media.title,
      artist: media.artist,
      album: media.stationName,
      imageUrl: media.imageUrl?.toString(),
    );
    if (!ok) throw StateError('Cast load failed: $media');
  }

  @override
  Future<void> stopMedia() => _bridge.stopMedia();

  @override
  void setVolume(double volume) => _bridge.setVolume(volume);

  @override
  Future<void> dispose() async {
    _closed = true;
    await _devices.close();
    await _links.close();
  }
}

/// Starts the web backend: only with consent, a supporting browser and a
/// loaded SDK; otherwise `null` (cast button stays inactive).
Future<CastBackend?> createBrowserCastBackend(BrowserCastBridge bridge) async {
  if (!bridge.supported || bridge.decision != true) return null;
  if (!await bridge.loadSdk()) return null;
  return BrowserCastBackend(bridge);
}
