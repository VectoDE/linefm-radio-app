import 'dart:ui' show Color;

import 'package:flutter/foundation.dart'
    show ValueListenable, ValueNotifier, visibleForTesting;
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_config.dart';

/// Aktuelle Senderliste.
///
/// Quelle ist allein config/stations.yaml: main() laedt die
/// mitgelieferte Fassung vor dem ersten Bild (`loadBundledStations`), danach
/// ersetzt eine nachgeladene, gepruefte Fassung die Liste zur Laufzeit
/// ([applyStations]). Wer die Liste anzeigt, hoert auf
/// [stationsCatalogListenable] (bzw. `stationsCatalogProvider`); wer sie nur
/// im Moment braucht (Weiter/Zurueck, Deep Link, Wecker), liest
/// [stationsCatalog].
///
/// Nur aktive Sender stehen in der Liste; ausgeblendete (`"aktiv": false`)
/// verhalten sich wie entfernte, ihre Kuerzel bleiben in Favoriten aber
/// gespeichert und tauchen wieder auf, sobald der Sender zurueck ist.
final ValueNotifier<List<Station>> _catalog = ValueNotifier<List<Station>>(
  const <Station>[],
);

/// Kuerzel, fuer die die App native Logos mitbringt (Android-Drawable
/// `auto_station_<slug>`, iOS-Bild `station_<slug>`): genau die Sender der
/// mitgelieferten Datei mit `logoDatei`.
Set<String> _nativeLogoSlugs = const <String>{};

/// Logo-Dateien, die diese App-Version mitbringt.
Set<String> _bundledLogoAssets = const <String>{};

/// Die angezeigten Sender in Dateireihenfolge. Nie leer, sobald main() die
/// mitgelieferte Datei geladen hat.
List<Station> get stationsCatalog => _catalog.value;

/// Meldet jede Aenderung der Senderliste.
ValueListenable<List<Station>> get stationsCatalogListenable => _catalog;

/// Sender mit Kuerzel [slug] aus der aktuellen Liste, sonst null (auch fuer
/// entfernte oder ausgeblendete Sender).
Station? stationBySlug(String slug) {
  for (final s in _catalog.value) {
    if (s.slug == slug) return s;
  }
  return null;
}

/// Sender fuer einen Wecker: der eingestellte, sonst (entfernt oder
/// ausgeblendet) der erste der Liste. Ein Wecker soll in jedem Fall wecken;
/// die Wecker-Seite zeigt dazu einen Hinweis.
Station alarmStationFor(String slug) =>
    stationBySlug(slug) ?? _catalog.value.first;

/// Platzhalter fuer gespeicherte Eintraege (z. B. Song-Favoriten) eines
/// Senders, der nicht mehr in der Liste steht: Kuerzel als Name, neutrale
/// Farbe. Wird nur angezeigt, nie abgespielt.
Station unknownStation(String slug, {String? logoUrl}) => Station(
  slug: slug,
  displayName: slug,
  color: const Color(0xFF5B6475),
  logoUrl: logoUrl ?? '',
);

/// Bringt die App fuer [station] ein natives Logo mit (Android Auto,
/// Homescreen-Widget, CarPlay)? Sonst zeigen diese einen neutralen Ersatz.
bool hasNativeStationLogo(Station station) =>
    _nativeLogoSlugs.contains(station.slug);

/// Logo-Dateien dieser App-Version (fuer die Pruefung nachgeladener Listen).
Set<String> get bundledStationLogoAssets => _bundledLogoAssets;

/// Wandelt einen geprueften Eintrag in einen Sender.
Station stationFromConfig(StationConfigEntry entry) => Station(
  slug: entry.slug,
  displayName: entry.name,
  color: Color(entry.color),
  logoUrl: entry.logoUrl,
  logoAsset: entry.logoAsset,
);

/// Uebernimmt die mitgelieferte Datei (main(), einmal beim Start). Wirft,
/// wenn sie ungueltig ist; das verhindert schon die CI (Senderliste pruefen).
void installBundledStations(StationsConfigResult result) {
  if (!result.ok) {
    throw StateError(
      'Mitgelieferte Senderliste ungueltig: ${result.errors.join('; ')}',
    );
  }
  _bundledLogoAssets = <String>{
    for (final e in result.entries)
      if (e.logoAsset != null) e.logoAsset!,
  };
  _nativeLogoSlugs = <String>{
    for (final e in result.entries)
      if (e.logoAsset != null) e.slug,
  };
  _catalog.value = List<Station>.unmodifiable(
    result.active.map(stationFromConfig),
  );
}

/// Ersetzt die Senderliste durch eine gepruefte Fassung. Leere Listen werden
/// nie uebernommen. Liefert true, wenn sich etwas geaendert hat.
bool applyStations(List<Station> next) {
  if (next.isEmpty || sameStationList(next, _catalog.value)) return false;
  _catalog.value = List<Station>.unmodifiable(next);
  return true;
}

/// Gleiche Sender mit gleichen Angaben in gleicher Reihenfolge?
bool sameStationList(List<Station> a, List<Station> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!a[i].sameAs(b[i])) return false;
  }
  return true;
}

/// Nur fuer Tests: Liste und native Logos direkt setzen.
@visibleForTesting
void setStationsForTest(
  List<Station> stations, {
  Set<String>? nativeLogoSlugs,
}) {
  _nativeLogoSlugs =
      nativeLogoSlugs ??
      <String>{
        for (final s in stations)
          if (s.logoAsset != null) s.slug,
      };
  _bundledLogoAssets = <String>{
    for (final s in stations)
      if (s.logoAsset != null) s.logoAsset!,
  };
  _catalog.value = List<Station>.unmodifiable(stations);
}
