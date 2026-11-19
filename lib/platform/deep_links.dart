import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';

/// Deep Links `linefm://play?station=slug` (App) und
/// `https://app.linefm.de/?station=slug` (Web, Spec 2.2). Besitzer: P21.
///
/// Wege in die App:
/// - Web: Start-Adresse (`Uri.base`) wertet der PlayerController beim Start
///   aus.
/// - Android/iOS: das Framework meldet Link-Intents bzw. URL-Schemata als
///   Routeninformation. Beim Kaltstart steht der Link in
///   `PlatformDispatcher.defaultRouteName`, laufend kommt er ueber
///   `didPushRouteInformation` ([initDeepLinks]).
/// - Windows/Linux: Link als Startargument bzw. von der zweiten Instanz
///   ([DeepLinks.dispatchFromArguments]; P18 ruft es auf).
///
/// Links kommen ueber [stream] an. Treffen sie ein, bevor jemand zuhoert
/// (Kaltstart), werden sie gemerkt und beim ersten Zuhoerer zugestellt.
class DeepLinks {
  DeepLinks._();

  static final StreamController<Uri> _controller =
      StreamController<Uri>.broadcast(
        onListen: () => scheduleMicrotask(_flushPending),
      );
  static final List<Uri> _pending = <Uri>[];
  static Uri? _last;
  static DateTime? _lastAt;

  /// Zeitfenster, in dem derselbe Link nur einmal zaehlt (Kaltstart meldet
  /// ihn teils ueber zwei Wege).
  static const Duration duplicateWindow = Duration(seconds: 2);

  /// Eingehende Links (Kaltstart-Link zuerst, danach laufende). Nur Links
  /// mit bekanntem Sender.
  static Stream<Uri> get stream => _controller.stream;

  /// Fuer Plattformcode und Tests. Links ohne bekannten Sender werden
  /// verworfen.
  static void dispatch(Uri uri, {DateTime? now}) {
    if (stationFromUri(uri) == null) return;
    final at = now ?? DateTime.now();
    final last = _last;
    final lastAt = _lastAt;
    if (last == uri &&
        lastAt != null &&
        at.difference(lastAt) < duplicateWindow) {
      return;
    }
    _last = uri;
    _lastAt = at;
    if (_controller.hasListener) {
      _controller.add(uri);
    } else {
      _pending.add(uri);
    }
  }

  /// Startargumente der Desktop-App bzw. Argumente der zweiten Instanz.
  static void dispatchFromArguments(Iterable<String> arguments) {
    for (final arg in arguments) {
      final uri = Uri.tryParse(arg);
      if (uri != null) dispatch(uri);
    }
  }

  /// Nur fuer Tests: Zustand zuruecksetzen.
  static void resetForTest() {
    _pending.clear();
    _last = null;
    _lastAt = null;
  }

  static void _flushPending() {
    if (!_controller.hasListener) return;
    final items = List<Uri>.of(_pending);
    _pending.clear();
    items.forEach(_controller.add);
  }

  /// Liest den Sender aus einem Link, null wenn unbekannt oder kein
  /// LINEFM-Link.
  ///
  /// Gueltig: `linefm://play?station=slug` und `http(s)://<Host>/?station=slug`
  /// (beliebiger Pfad, damit benannte Web-Routen wie `/history?station=slug`
  /// funktionieren). Andere Schemata (z. B. `javascript:`) werden abgelehnt.
  static Station? stationFromUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'linefm') {
      final target = uri.host.isNotEmpty
          ? uri.host
          : uri.pathSegments.firstOrNull;
      if (target?.toLowerCase() != 'play') return null;
    } else if (scheme != 'http' && scheme != 'https') {
      return null;
    }
    final slug = uri.queryParameters['station'];
    if (slug == null || slug.isEmpty) return null;
    return stationBySlug(slug);
  }
}

/// Meldet Routeninformationen des Systems (Link-Intents, URL-Schemata) an
/// [DeepLinks], solange sie einen LINEFM-Sender enthalten; alles andere bleibt
/// unberuehrt.
class DeepLinkObserver with WidgetsBindingObserver {
  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    if (DeepLinks.stationFromUri(routeInformation.uri) == null) return false;
    DeepLinks.dispatch(routeInformation.uri);
    return true;
  }
}

DeepLinkObserver? _observer;

/// Initialisiert die Deep-Link-Auswertung. Web: nichts zu tun (die
/// Start-Adresse liest der PlayerController).
Future<void> initDeepLinks() async {
  if (kIsWeb || _observer != null) return;
  final binding = WidgetsBinding.instance;
  _observer = DeepLinkObserver();
  binding.addObserver(_observer!);
  final initial = Uri.tryParse(PlatformDispatcher.instance.defaultRouteName);
  if (initial != null) DeepLinks.dispatch(initial);
}
