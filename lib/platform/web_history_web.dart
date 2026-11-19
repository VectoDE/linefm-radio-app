import 'package:web/web.dart' as web;

/// Aktuelle Adresse des Tabs.
Uri? currentBrowserUri() => Uri.base;

/// Ersetzt Pfad und Suchteil der Adressleiste ohne Neuladen und ohne neuen
/// Verlaufseintrag. Das Fragment (`#...`) der Flutter-Hash-Strategie bleibt.
void replaceBrowserPath(String path, {String? query}) {
  final location = web.window.location;
  final search = (query == null || query.isEmpty) ? '' : '?$query';
  final next = '$path$search${location.hash}';
  if (next == '${location.pathname}${location.search}${location.hash}') return;
  web.window.history.replaceState(null, '', next);
}
