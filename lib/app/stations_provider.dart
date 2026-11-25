import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';

/// Aktuelle Senderliste fuer die Oberflaeche (Issue #91). Baut neu, sobald
/// eine nachgeladene Fassung die Liste aendert; Senderliste, Favoriten-
/// Sender, Wecker-Auswahl und aktiver Sender hoeren darauf.
final stationsCatalogProvider = Provider<List<Station>>((ref) {
  void changed() => ref.invalidateSelf();
  stationsCatalogListenable.addListener(changed);
  ref.onDispose(() => stationsCatalogListenable.removeListener(changed));
  return stationsCatalog;
});
