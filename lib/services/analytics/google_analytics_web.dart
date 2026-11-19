import 'dart:js_interop';

import 'package:linefm_radio/services/analytics/google_analytics_bridge.dart';

@JS('linefmAnalytics')
external _AnalyticsApi? get _api;

extension type _AnalyticsApi._(JSObject _) implements JSObject {
  external JSString state();
  external JSBoolean configure(JSString gtmId, JSString ga4Id);
  external void grant();
  external void deny();
  external void reset();
}

GoogleAnalyticsBridge createGoogleAnalyticsBridge() => _api == null
    ? const NoopGoogleAnalyticsBridge()
    : const _WebGoogleAnalyticsBridge();

class _WebGoogleAnalyticsBridge implements GoogleAnalyticsBridge {
  const _WebGoogleAnalyticsBridge();

  @override
  bool? get decision => switch (_api?.state().toDart) {
    'granted' => true,
    'denied' => false,
    _ => null,
  };

  @override
  void configure({required String gtmId, required String ga4Id}) =>
      _api?.configure(gtmId.toJS, ga4Id.toJS);

  @override
  void grant() => _api?.grant();

  @override
  void deny() => _api?.deny();

  @override
  void reset() => _api?.reset();
}
