import 'dart:convert';

import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';

/// Favoriten-Sender (Issue #42, Entscheidung 49): Sender, die per Stern auf
/// der Stationskarte gemerkt werden. Getrennt von den Song-Favoriten
/// ([FavoritesLogic]) und unter eigenem Speicherschluessel.
///
/// Gespeichert wird nur die Liste der Slugs. Angezeigt werden die Sender in
/// der Reihenfolge der Senderliste, damit Plaetze im Auto-Menue und in der
/// App stabil bleiben, egal in welcher Reihenfolge gemerkt wurde.
class FavoriteStationsLogic {
  const FavoriteStationsLogic._();

  /// Merkt [station] oder entfernt sie, wenn sie schon gemerkt ist.
  static Set<String> toggle(Set<String> slugs, Station station) {
    final next = <String>{...slugs};
    if (!next.remove(station.slug)) next.add(station.slug);
    return Set<String>.unmodifiable(next);
  }

  static bool contains(Set<String> slugs, Station station) =>
      slugs.contains(station.slug);

  /// Gemerkte Sender in der Reihenfolge von [catalog]. Unbekannte Slugs
  /// (z. B. ein spaeter entfernter Sender) fallen weg.
  static List<Station> stations(
    Set<String> slugs, {
    List<Station> catalog = stationsCatalog,
  }) => <Station>[
    for (final s in catalog)
      if (slugs.contains(s.slug)) s,
  ];

  /// JSON-Liste der Slugs in Senderlisten-Reihenfolge.
  static String encode(Set<String> slugs) =>
      jsonEncode(<String>[for (final s in stations(slugs)) s.slug]);

  /// Liest den Speicherwert. Kaputtes JSON, fremde Strukturen und unbekannte
  /// Sender ergeben keine Eintraege statt eines Fehlers.
  static Set<String> decode(String? json) {
    if (json == null || json.trim().isEmpty) return const <String>{};
    final Object? data;
    try {
      data = jsonDecode(json);
    } on FormatException {
      return const <String>{};
    }
    if (data is! List) return const <String>{};
    return Set<String>.unmodifiable(<String>{
      for (final item in data)
        if (item is String && stationBySlug(item) != null) item,
    });
  }
}
