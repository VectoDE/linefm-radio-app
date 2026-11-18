import 'dart:convert';

import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/track.dart';

/// Plattformneutrale Favoriten-Logik. Verhalten der Web-App: neue Favoriten
/// vorn (`unshift`), erneutes Merken entfernt den Eintrag.
class FavoritesLogic {
  const FavoritesLogic._();

  static String keyFor({
    required String stationSlug,
    required String artist,
    required String title,
  }) => '$stationSlug:${artist.toLowerCase()}:${title.toLowerCase()}';

  /// Baut einen Favoriten fuer den laufenden Titel eines Senders.
  /// Cover-Rueckfall wie Web-App: Titel-Cover, sonst Senderlogo.
  static Favorite fromTrack({
    required String stationSlug,
    required Track track,
    required DateTime savedAt,
    String? stationLogoUrl,
  }) => Favorite(
    key: keyFor(
      stationSlug: stationSlug,
      artist: track.artist,
      title: track.title,
    ),
    stationSlug: stationSlug,
    title: track.title,
    artist: track.artist,
    artworkUrl: track.artworkUrl ?? stationLogoUrl,
    stationLogoUrl: stationLogoUrl,
    savedAt: savedAt,
  );

  static bool contains(List<Favorite> list, String key) =>
      list.any((f) => f.key == key);

  /// Neue Favoriten vorn (wie unshift der Web-App).
  static List<Favorite> toggle(List<Favorite> list, Favorite item) {
    if (contains(list, item.key)) return remove(list, item.key);
    return <Favorite>[item, ...list];
  }

  static List<Favorite> remove(List<Favorite> list, String key) =>
      list.where((f) => f.key != key).toList();

  /// Serialisiert fuer den Speicher (JSON-Liste).
  static String encode(List<Favorite> list) =>
      jsonEncode(list.map((f) => f.toJson()).toList());

  /// Liest JSON aus dem Speicher oder aus der Web-App (`linefm-favorites`).
  /// Kaputtes JSON oder fremde Strukturen ergeben eine leere Liste, einzelne
  /// unlesbare Eintraege werden uebersprungen. Doppelte Schluessel: der erste
  /// (neueste) bleibt.
  static List<Favorite> decode(String? json) {
    if (json == null || json.trim().isEmpty) return <Favorite>[];
    final Object? data;
    try {
      data = jsonDecode(json);
    } on FormatException {
      return <Favorite>[];
    }
    if (data is! List) return <Favorite>[];
    final seen = <String>{};
    final result = <Favorite>[];
    for (final item in data) {
      final favorite = Favorite.tryFromJson(item);
      if (favorite != null && seen.add(favorite.key)) result.add(favorite);
    }
    return result;
  }
}
