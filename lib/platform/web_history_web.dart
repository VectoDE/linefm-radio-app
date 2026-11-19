import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Aktuelle Adresse des Tabs.
Uri? currentBrowserUri() => Uri.base;

/// Setzt Pfad und Suchteil der Adressleiste ohne Neuladen. Mit [push] mit
/// neuem Verlaufseintrag (Zurueck-Taste), sonst ersetzend. Das Fragment
/// (`#...`) der Flutter-Hash-Strategie bleibt.
void setBrowserPath(String path, {String? query, bool push = false}) {
  final location = web.window.location;
  final search = (query == null || query.isEmpty) ? '' : '?$query';
  final next = '$path$search${location.hash}';
  if (next == '${location.pathname}${location.search}${location.hash}') return;
  if (push) {
    web.window.history.pushState(null, '', next);
  } else {
    web.window.history.replaceState(null, '', next);
  }
}

/// Zurueck/Vor im Browser (popstate).
void Function() listenBrowserPop(void Function(String path) onChange) {
  final handler = ((web.Event _) => onChange(
    web.window.location.pathname,
  )).toJS;
  web.window.addEventListener('popstate', handler);
  return () => web.window.removeEventListener('popstate', handler);
}
