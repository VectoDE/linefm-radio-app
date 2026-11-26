import 'dart:js_interop';

import 'package:linefm_radio/services/cast/browser_cast.dart';

@JS('linefmCast')
external _CastApi? get _api;

extension type _CastApi._(JSObject _) implements JSObject {
  external JSBoolean supported();
  external JSString state();
  external void grant();
  external void deny();
  external void reset();
  external JSPromise<JSBoolean> load();
  external void onChange(JSFunction listener);
  external JSString castState();
  external JSString deviceId();
  external JSString deviceName();
  external JSPromise<JSBoolean> requestSession();
  external void endSession();
  external JSPromise<JSBoolean> loadMedia(
    JSString url,
    JSString contentType,
    JSString title,
    JSString artist,
    JSString album,
    JSString? image,
  );
  external JSPromise<JSAny?> stopMedia();
  external void setVolume(JSNumber volume);
}

BrowserCastBridge createBrowserCastBridge() => _api == null
    ? const NoopBrowserCastBridge()
    : const _WebBrowserCastBridge();

class _WebBrowserCastBridge implements BrowserCastBridge {
  const _WebBrowserCastBridge();

  _CastApi get _js => _api!;

  @override
  bool get supported => _js.supported().toDart;

  @override
  bool? get decision => switch (_js.state().toDart) {
    'granted' => true,
    'denied' => false,
    _ => null,
  };

  @override
  void grant() => _js.grant();

  @override
  void deny() => _js.deny();

  @override
  void reset() => _js.reset();

  @override
  Future<bool> loadSdk() async => (await _js.load().toDart).toDart;

  @override
  void onChange(void Function() listener) => _js.onChange(listener.toJS);

  @override
  String get castState => _js.castState().toDart;

  @override
  String get deviceId => _js.deviceId().toDart;

  @override
  String get deviceName => _js.deviceName().toDart;

  @override
  Future<bool> requestSession() async =>
      (await _js.requestSession().toDart).toDart;

  @override
  void endSession() => _js.endSession();

  @override
  Future<bool> loadMedia({
    required String url,
    required String contentType,
    required String title,
    required String artist,
    required String album,
    String? imageUrl,
  }) async =>
      (await _js
              .loadMedia(
                url.toJS,
                contentType.toJS,
                title.toJS,
                artist.toJS,
                album.toJS,
                imageUrl?.toJS,
              )
              .toDart)
          .toDart;

  @override
  Future<void> stopMedia() async {
    await _js.stopMedia().toDart;
  }

  @override
  void setVolume(double volume) => _js.setVolume(volume.toJS);
}
