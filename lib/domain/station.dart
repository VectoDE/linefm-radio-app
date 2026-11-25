import 'dart:ui' show Color;

/// Ein Sender. Die Liste kommt aus config/stations.yaml,
/// siehe `stationsCatalog`.
class Station {
  const Station({
    required this.slug,
    required this.displayName,
    required this.color,
    required this.logoUrl,
    this.logoAsset,
  });

  /// Kuerzel bei laut.fm und zugleich die stabile Kennung: Favoriten,
  /// Wecker, "zuletzt gehoert", Deep Links und Auto-Menue speichern nur das
  /// Kuerzel.
  final String slug;
  final String displayName;
  final Color color;

  /// Logo im Netz (Auto-Menue, Cast, Benachrichtigung, Senderliste fuer
  /// Sender ohne mitgeliefertes Logo).
  final String logoUrl;

  /// Mitgeliefertes Logo; null bei Sendern, die erst nachgeladen wurden.
  final String? logoAsset;

  /// Stabile Kennung, gleich dem Kuerzel. Fruehere Versionen fuehrten
  /// laufende Nummern, gespeichert wurde aber immer nur das Kuerzel.
  String get id => slug;

  /// Stream-Adresse, aus dem Kuerzel abgeleitet (nicht frei eintragbar).
  String get fallbackStreamUrl => 'https://stream.laut.fm/$slug';

  /// Gleiche Angaben (fuer den Vergleich zweier Senderlisten).
  bool sameAs(Station other) =>
      other.slug == slug &&
      other.displayName == displayName &&
      other.color == color &&
      other.logoUrl == logoUrl &&
      other.logoAsset == logoAsset;

  /// Gleich ist ein Sender mit gleichem Kuerzel, auch wenn eine nachgeladene
  /// Liste Name oder Farbe geaendert hat.
  @override
  bool operator ==(Object other) => other is Station && other.slug == slug;

  @override
  int get hashCode => slug.hashCode;

  @override
  String toString() => 'Station($slug)';
}
