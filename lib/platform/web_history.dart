/// Adressleiste des Browsers lesen/setzen (nur Web, sonst wirkungslos).
library;

export 'web_history_stub.dart'
    if (dart.library.js_interop) 'web_history_web.dart';
