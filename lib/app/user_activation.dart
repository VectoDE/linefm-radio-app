// Web: Hat der Nutzer schon mit der Seite interagiert (Autoplay-Sperre der
// Browser)? Auf allen anderen Plattformen immer `true`.
export 'user_activation_stub.dart'
    if (dart.library.js_interop) 'user_activation_web.dart';
