import 'dart:convert';

import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/stations_config.dart';

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

  /// Gemerkte Sender in der Reihenfolge von [catalog] (Standard: aktuelle
  /// Senderliste). Slugs ohne Sender in der Liste (entfernt oder
  /// ausgeblendet, Issue #91) werden nicht angezeigt.
  static List<Station> stations(Set<String> slugs, {List<Station>? catalog}) =>
      <Station>[
        for (final s in catalog ?? stationsCatalog)
          if (slugs.contains(s.slug)) s,
      ];

  /// JSON-Liste der Slugs, bekannte in Senderlisten-Reihenfolge, danach die
  /// uebrigen. Slugs gerade ausgeblendeter Sender bleiben gespeichert, damit
  /// der Stern wieder da ist, wenn der Sender zurueckkommt (Issue #91).
  static String encode(Set<String> slugs) {
    final known = <String>[for (final s in stations(slugs)) s.slug];
    final rest = slugs.where((s) => !known.contains(s)).toList()..sort();
    return jsonEncode(<String>[...known, ...rest]);
  }

  /// Liest den Speicherwert. Kaputtes JSON, fremde Strukturen und Eintraege,
  /// die kein gueltiges laut.fm-Kuerzel sind, ergeben keine Eintraege statt
  /// eines Fehlers. Gueltige Kuerzel bleiben, auch wenn der Sender gerade
  /// nicht in der Liste steht.
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
        if (item is String && isValidStationSlug(item)) item,
    });
  }
}
