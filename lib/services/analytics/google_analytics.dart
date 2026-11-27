// Bruecke zu web/analytics.js (Reichweitenmessung mit Google, nur Web).
// Auf allen anderen Plattformen ohne Wirkung.
export 'google_analytics_stub.dart'
    if (dart.library.js_interop) 'google_analytics_web.dart';
