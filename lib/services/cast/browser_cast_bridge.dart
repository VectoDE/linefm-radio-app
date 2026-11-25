// Bridge to web/cast.js (Google Cast in the web version). No effect on other
// platforms.
export 'browser_cast_bridge_stub.dart'
    if (dart.library.js_interop) 'browser_cast_bridge_web.dart';
