import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';

/// Default Media Receiver von Google (kein eigener Receiver, keine
/// Registrierung nötig).
const String _receiverAppId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;

/// Nur Android und iOS; das Plugin hat keine Desktop-/Web-Umsetzung.
bool get _supported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Initialisiert den Cast-Kontext. `null`, wenn die Plattform kein Cast hat
/// oder die Initialisierung scheitert (z. B. keine Google Play Services).
Future<CastBackend?> createPluginBackend() async {
  if (!_supported) return null;
  try {
    GoogleCastLogger.level = CastLogLevel.error;
    final GoogleCastOptions options = Platform.isAndroid
        ? GoogleCastOptionsAndroid(appId: _receiverAppId)
        : IOSGoogleCastOptions(
            GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(
              _receiverAppId,
            ),
          );
    final ok = await GoogleCastContext.instance.setSharedInstanceWithOptions(
      options,
    );
    if (!ok) {
      logError('Cast-Kontext nicht verfügbar', 'setSharedInstance=false');
      return null;
    }
    return _PluginCastBackend();
  } on Object catch (e) {
    logError('Cast nicht verfügbar (Play-Dienste?)', e);
    return null;
  }
}

class _PluginCastBackend implements CastBackend {
  _PluginCastBackend() {
    _devices = GoogleCastDiscoveryManager.instance.devices
        .map(_toDevice)
        .toList();
    _link = _toLink(GoogleCastSessionManager.instance.currentSession);
    _subs
      ..add(
        GoogleCastDiscoveryManager.instance.devicesStream.listen((list) {
          _devices = list.map(_toDevice).toList();
          if (!_devicesController.isClosed) _devicesController.add(_devices);
        }),
      )
      ..add(
        GoogleCastSessionManager.instance.currentSessionStream.listen((s) {
          final next = _toLink(s);
          if (next == _link) return;
          _link = next;
          if (!_linkController.isClosed) _linkController.add(next);
        }),
      );
  }

  final List<StreamSubscription<Object?>> _subs =
      <StreamSubscription<Object?>>[];
  final StreamController<List<CastDevice>> _devicesController =
      StreamController<List<CastDevice>>.broadcast();
  final StreamController<CastLinkState> _linkController =
      StreamController<CastLinkState>.broadcast();
  late List<CastDevice> _devices;
  late CastLinkState _link;

  static CastDevice _toDevice(GoogleCastDevice d) =>
      CastDevice(id: d.deviceID, name: d.friendlyName);

  static CastLinkState _toLink(GoogleCastSession? session) {
    if (session == null) return CastLinkState.none;
    final device = session.device;
    final link = switch (session.connectionState) {
      GoogleCastConnectState.disconnected => CastLink.disconnected,
      GoogleCastConnectState.connecting => CastLink.connecting,
      GoogleCastConnectState.connected => CastLink.connected,
      GoogleCastConnectState.disconnecting => CastLink.disconnecting,
    };
    return CastLinkState(link, device == null ? null : _toDevice(device));
  }

  @override
  List<CastDevice> get devices => _devices;

  @override
  Stream<List<CastDevice>> get devicesStream => _devicesController.stream;

  @override
  CastLinkState get link => _link;

  @override
  Stream<CastLinkState> get linkStream => _linkController.stream;

  @override
  Future<void> startDiscovery({bool activeScan = false}) =>
      GoogleCastDiscoveryManager.instance.startDiscovery(
        activeScan: activeScan,
      );

  @override
  Future<void> stopDiscovery() =>
      GoogleCastDiscoveryManager.instance.stopDiscovery();

  @override
  Future<bool> startSession(CastDevice device) async {
    final match = GoogleCastDiscoveryManager.instance.devices
        .where((d) => d.deviceID == device.id)
        .firstOrNull;
    if (match == null) return false;
    return GoogleCastSessionManager.instance.startSessionWithDevice(match);
  }

  @override
  Future<void> endSession() async {
    await GoogleCastSessionManager.instance.endSessionAndStopCasting();
  }

  @override
  Future<void> load(CastMedia media) {
    final image = media.imageUrl;
    final images = image == null
        ? null
        : <GoogleCastImage>[
            GoogleCastImage(url: image, height: 640, width: 640),
          ];
    // Die Basisklasse genügt: iOS und Android lesen dieselbe Map.
    final metadata = GoogleCastMusicMediaMetadata(
      title: media.title,
      artist: media.artist,
      albumName: media.stationName,
      images: images,
    );
    final url = media.streamUrl;
    final info = Platform.isAndroid
        ? GoogleCastMediaInformationAndroid(
            contentId: url.toString(),
            contentUrl: url,
            streamType: CastMediaStreamType.live,
            contentType: 'audio/mpeg',
            metadata: metadata,
          )
        : GoogleCastMediaInformationIOS(
            contentId: url.toString(),
            contentUrl: url,
            streamType: CastMediaStreamType.live,
            contentType: 'audio/mpeg',
            metadata: metadata,
          );
    return GoogleCastRemoteMediaClient.instance.loadMedia(info);
  }

  @override
  Future<void> stopMedia() => GoogleCastRemoteMediaClient.instance.stop();

  @override
  void setVolume(double volume) =>
      GoogleCastSessionManager.instance.setDeviceVolume(volume.clamp(0, 1));

  @override
  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _devicesController.close();
    await _linkController.close();
  }
}
