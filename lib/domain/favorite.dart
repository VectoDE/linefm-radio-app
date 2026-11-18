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

  /// Liest den eigenen Speicherstand und das Format der Web-App
  /// (`key`, `station`, `title`, `artist`, `artwork`, `stationLogo`).
  ///
  /// Tolerant: gibt `null` zurueck, wenn Titel oder Sender nicht bestimmbar
  /// sind. Ein fehlender Schluessel wird nach der Web-App-Regel neu gebildet.
  static Favorite? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final title = _text(json['title']);
    if (title == null) return null;
    final artist = json['artist'] is String ? json['artist']! as String : '';
    final storedKey = _text(json['key']);
    final slug =
        _text(json['stationSlug']) ??
        _text(json['station']) ??
        _slugFromKey(storedKey);
    if (slug == null) return null;
    return Favorite(
      key: storedKey ?? '$slug:${artist.toLowerCase()}:${title.toLowerCase()}',
      stationSlug: slug,
      title: title,
      artist: artist,
      artworkUrl: _text(json['artworkUrl']) ?? _text(json['artwork']),
      stationLogoUrl:
          _text(json['stationLogoUrl']) ?? _text(json['stationLogo']),
      savedAt: json['savedAt'] is String
          ? DateTime.tryParse(json['savedAt']! as String)
          : null,
    );
  }

  /// Schluessel exakt wie die Web-App: stationSlug:artist:title, lowercase.
  final String key;
  final String stationSlug;
  final String title;
  final String artist;
  final String? artworkUrl;
  final String? stationLogoUrl;

  /// null bei aus der Web-App migrierten Favoriten ohne Datum.
  final DateTime? savedAt;

  Favorite copyWith({
    String? key,
    String? stationSlug,
    String? title,
    String? artist,
    String? artworkUrl,
    String? stationLogoUrl,
    DateTime? savedAt,
  }) => Favorite(
    key: key ?? this.key,
    stationSlug: stationSlug ?? this.stationSlug,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    artworkUrl: artworkUrl ?? this.artworkUrl,
    stationLogoUrl: stationLogoUrl ?? this.stationLogoUrl,
    savedAt: savedAt ?? this.savedAt,
  );

  /// Superset des Web-App-Formats (`station`, `artwork`, `stationLogo`), damit
  /// ein Rueckwechsel zur Web-App die Eintraege weiter lesen kann.
  Map<String, Object?> toJson() => <String, Object?>{
    'key': key,
    'station': stationSlug,
    'stationSlug': stationSlug,
    'title': title,
    'artist': artist,
    'artwork': artworkUrl ?? '',
    'artworkUrl': artworkUrl,
    'stationLogo': stationLogoUrl ?? '',
    'stationLogoUrl': stationLogoUrl,
    'savedAt': savedAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Favorite &&
      other.key == key &&
      other.stationSlug == stationSlug &&
      other.title == title &&
      other.artist == artist &&
      other.artworkUrl == artworkUrl &&
      other.stationLogoUrl == stationLogoUrl &&
      other.savedAt == savedAt;

  @override
  int get hashCode => Object.hash(
    key,
    stationSlug,
    title,
    artist,
    artworkUrl,
    stationLogoUrl,
    savedAt,
  );

  @override
  String toString() => 'Favorite($key)';
}

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

String? _slugFromKey(String? key) {
  if (key == null) return null;
  final index = key.indexOf(':');
  return index > 0 ? key.substring(0, index) : null;
}
