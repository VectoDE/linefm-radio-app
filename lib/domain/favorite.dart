class Favorite {
  const Favorite({
    required this.key,
    required this.stationSlug,
    required this.title,
    required this.artist,
    this.artworkUrl,
    this.stationLogoUrl,
    this.savedAt,
  });

  /// Schluessel exakt wie die Web-App: stationSlug:artist:title, lowercase.
  final String key;
  final String stationSlug;
  final String title;
  final String artist;
  final String? artworkUrl;
  final String? stationLogoUrl;

  /// null bei aus der Web-App migrierten Favoriten ohne Datum.
  final DateTime? savedAt;
}
