import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';

/// Schreibt Widget-Daten (home_widget). Android: P16, iOS: P17.
abstract interface class HomeWidgetSync {
  Future<void> update({Station? station, Track? track, required bool playing});
}

class NoopHomeWidgetSync implements HomeWidgetSync {
  const NoopHomeWidgetSync();

  @override
  Future<void> update({
    Station? station,
    Track? track,
    required bool playing,
  }) async {}
}

/// Initialisiert das Homescreen-Widget (No-Op bis P16/P17).
Future<void> initHomeWidget() async {}
