import 'package:web/web.dart' as web;

/// `performance.mark('linefm:<name>')`; Fehler (alte Browser) still schlucken,
/// die Messung darf die App nie stoeren.
void writeMark(String name) {
  try {
    web.window.performance.mark('linefm:$name');
  } on Object {
    // Ohne User-Timing-API keine Messung.
  }
}
