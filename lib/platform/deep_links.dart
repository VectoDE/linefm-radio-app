import 'dart:async';

import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';

/// Deep Links linefm://play?station=slug und Web ?station=slug (Spec 2.2).
/// Besitzer: P21.
class DeepLinks {
  DeepLinks._();

  static final StreamController<Uri> _controller =
      StreamController<Uri>.broadcast();

  /// Eingehende Links (Kaltstart-Link zuerst, danach laufende).
  static Stream<Uri> get stream => _controller.stream;

  /// Fuer Plattformcode und Tests.
  static void dispatch(Uri uri) => _controller.add(uri);

  /// Liest den Sender aus einem Link, null wenn unbekannt.
  static Station? stationFromUri(Uri uri) {
    final slug = uri.queryParameters['station'];
    return slug == null ? null : stationBySlug(slug);
  }
}

/// Initialisiert die Deep-Link-Auswertung (No-Op bis P21).
Future<void> initDeepLinks() async {}
