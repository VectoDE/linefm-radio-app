import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Im Browser gibt es keinen frei waehlbaren Ordner.
Future<String> saveToDownloadFolder(String fileName, Uint8List bytes) =>
    Future<String>.error(UnsupportedError('Kein Download-Ordner verfuegbar.'));

/// Startet einen Datei-Download ueber einen unsichtbaren Anker mit Blob-URL.
void triggerBrowserDownload(String fileName, Uint8List bytes, String mime) {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  // Der Browser braucht die URL noch kurz, um den Download zu starten.
  Timer(const Duration(seconds: 10), () => web.URL.revokeObjectURL(url));
}
