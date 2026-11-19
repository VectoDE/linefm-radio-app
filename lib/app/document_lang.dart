// Setzt <html lang> im Web passend zur aufgeloesten App-Sprache (Screenreader,
// Silbentrennung). Auf allen anderen Plattformen ohne Wirkung.
export 'document_lang_stub.dart'
    if (dart.library.js_interop) 'document_lang_web.dart';
