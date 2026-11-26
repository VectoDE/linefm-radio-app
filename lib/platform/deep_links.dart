import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/services.dart' show MethodCall, MethodChannel;
import 'package:flutter/widgets.dart';
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/stations_config.dart';

/// Deep Links `linefm://play?station=slug` (App) und
/// `https://app.linefm.de/?station=slug` (Web, Spec 2.2). Besitzer: P21.
///
/// Wege in die App:
/// - Web: Start-Adresse (`Uri.base`) wertet der PlayerController beim Start
///   aus.
/// - Android: eigener Kanal `de.linefm.app/deep_links` der MainActivity
///   (`getInitialLink` beim Start, `onLink` bei laufender App). Flutters
///   Routen-Deep-Linking ist dort aus (`shouldHandleDeeplinking`), damit ein
///   Link nicht doppelt bzw. als unbekannte Route ankommt. Quelle u. a. das
///   Homescreen-Widget.
/// - iOS: das Framework meldet URL-Schemata als Routeninformation. Beim
///   Kaltstart steht der Link in `PlatformDispatcher.defaultRouteName`,
///   laufend kommt er ueber `didPushRouteInformation` ([initDeepLinks]).
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

  static final StreamController<String> _unavailable =
      StreamController<String>.broadcast(
        onListen: () => scheduleMicrotask(_flushUnavailable),
      );
  static String? _pendingUnavailable;

  /// Eigene Links auf einen Sender, der nicht (mehr) in der Senderliste
  /// steht (entfernt oder ausgeblendet). Die App zeigt dazu einen
  /// Hinweis, spielt aber nichts.
  static Stream<String> get unavailable => _unavailable.stream;

  /// Fuer Plattformcode und Tests. Links ohne bekannten Sender werden
  /// verworfen; ist es ein eigener Link mit gueltigem Kuerzel, geht das
  /// Kuerzel an [unavailable].
  static void dispatch(Uri uri, {DateTime? now}) {
    if (stationFromUri(uri) == null) {
      final slug = slugFromUri(uri);
      if (slug != null) {
        if (_unavailable.hasListener) {
          _unavailable.add(slug);
        } else {
          _pendingUnavailable = slug;
        }
      }
      return;
    }
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
    _pendingUnavailable = null;
    _last = null;
    _lastAt = null;
  }

  static void _flushUnavailable() {
    final slug = _pendingUnavailable;
    if (slug == null || !_unavailable.hasListener) return;
    _pendingUnavailable = null;
    _unavailable.add(slug);
  }

  static void _flushPending() {
    if (!_controller.hasListener) return;
    final items = List<Uri>.of(_pending);
    _pending.clear();
    items.forEach(_controller.add);
  }

  /// Host der Web-App; nur dessen Links oeffnen einen Sender.
  static const String webHost = 'app.linefm.de';

  /// Liest den Sender aus einem Link, null wenn unbekannt oder kein
  /// LINEFM-Link.
  ///
  /// Gueltig: `linefm://play?station=slug` und
  /// `https://app.linefm.de/...?station=slug` (beliebiger Pfad, damit
  /// benannte Web-Routen wie `/history?station=slug` funktionieren). Fremde
  /// Hosts und Schemata (z. B. `javascript:`) werden abgelehnt.
  /// Im Browser zaehlt zusaetzlich der eigene Host der Seite ([ownHost],
  /// Standard `Uri.base.host`), damit Vorschau- und Testumgebungen gehen.
  static Station? stationFromUri(Uri uri, {String? ownHost}) {
    final slug = slugFromUri(uri, ownHost: ownHost);
    return slug == null ? null : stationBySlug(slug);
  }

  /// Kuerzel aus einem eigenen Link (Schema/Host wie [stationFromUri]),
  /// nur wenn es das laut.fm-Format hat; ob der Sender in der aktuellen
  /// Liste steht, prueft [stationFromUri]. Diese Pruefung gilt auf allen
  /// Plattformen: Android (MainActivity.kt) reicht nur Schema und Host
  /// gefiltert durch, iOS/macOS und Desktop gar nicht vorgefiltert, die
  /// verbindliche Entscheidung faellt immer hier gegen die aktuell gueltige
  /// Senderliste.
  static String? slugFromUri(Uri uri, {String? ownHost}) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'linefm') {
      final target = uri.host.isNotEmpty
          ? uri.host
          : uri.pathSegments.firstOrNull;
      if (target?.toLowerCase() != 'play') return null;
    } else if (scheme == 'http' || scheme == 'https') {
      final host = uri.host.toLowerCase();
      final own = (ownHost ?? (kIsWeb ? Uri.base.host : '')).toLowerCase();
      if (host != webHost && (own.isEmpty || host != own)) return null;
    } else {
      return null;
    }
    final String? slug;
    try {
      slug = uri.queryParameters['station'];
    } on FormatException {
      return null;
    }
    if (slug == null || !isValidStationSlug(slug)) return null;
    return slug;
  }
}

/// Meldet Routeninformationen des Systems (Link-Intents, URL-Schemata) an
/// [DeepLinks], solange sie ein LINEFM-Senderkuerzel enthalten; alles andere
/// bleibt unberuehrt.
class DeepLinkObserver with WidgetsBindingObserver {
  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    // Eigener Link mit gueltigem Kuerzel: annehmen, auch wenn der Sender
    // nicht mehr in der Liste steht (dann Hinweis statt Navigation).
    if (DeepLinks.slugFromUri(routeInformation.uri) == null) return false;
    DeepLinks.dispatch(routeInformation.uri);
    return true;
  }
}

DeepLinkObserver? _observer;

/// Kanal der Android-MainActivity (siehe MainActivity.kt).
const MethodChannel androidDeepLinkChannel = MethodChannel(
  'de.linefm.app/deep_links',
);

MethodChannel? _boundChannel;

/// Bindet den Android-Kanal: Start-Link holen und laufende Links annehmen.
/// Beide gehen ueber [DeepLinks.dispatch] (Kaltstart-Puffer,
/// Duplikatfilter).
@visibleForTesting
Future<void> bindAndroidDeepLinks([
  MethodChannel channel = androidDeepLinkChannel,
]) async {
  if (identical(_boundChannel, channel)) return;
  _boundChannel = channel;
  channel.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'onLink') _dispatchString(call.arguments);
    return null;
  });
  try {
    _dispatchString(await channel.invokeMethod<String>('getInitialLink'));
  } on Object catch (e) {
    logError('Start-Link nicht gelesen', e);
  }
}

/// Nur fuer Tests: Kanalbindung loesen.
@visibleForTesting
void unbindAndroidDeepLinksForTest() {
  _boundChannel?.setMethodCallHandler(null);
  _boundChannel = null;
}

void _dispatchString(Object? value) {
  if (value is! String || value.isEmpty) return;
  final uri = Uri.tryParse(value);
  if (uri != null) DeepLinks.dispatch(uri);
}

/// Initialisiert die Deep-Link-Auswertung. Web: nichts zu tun (die
/// Start-Adresse liest der PlayerController).
Future<void> initDeepLinks() async {
  if (kIsWeb || _observer != null) return;
  final binding = WidgetsBinding.instance;
  _observer = DeepLinkObserver();
  binding.addObserver(_observer!);
  final initial = Uri.tryParse(PlatformDispatcher.instance.defaultRouteName);
  if (initial != null) DeepLinks.dispatch(initial);
  if (defaultTargetPlatform == TargetPlatform.android) {
    await bindAndroidDeepLinks();
  }
}
