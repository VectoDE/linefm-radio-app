/// Ein Song mit optionalen Zeit- und Coverangaben.
class Track {
  const Track({
    required this.artist,
    required this.title,
    this.album,
    this.artworkUrl,
    this.startedAt,
    this.endsAt,
  });

  /// Tolerant: fehlende oder falsch typisierte Felder fuehren zu `null`.
  /// Gibt `null` zurueck, wenn weder Kuenstler noch Titel vorhanden sind.
  static Track? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final artist = _string(json['artist']);
    final title = _string(json['title']);
    if (artist == null || title == null) return null;
    return Track(
      artist: artist,
      title: title,
      album: _string(json['album']),
      artworkUrl: _string(json['artworkUrl']),
      startedAt: _date(json['startedAt']),
      endsAt: _date(json['endsAt']),
    );
  }

  final String artist;
  final String title;
  final String? album;
  final String? artworkUrl;
  final DateTime? startedAt;
  final DateTime? endsAt;

  Track copyWith({
    String? artist,
    String? title,
    String? album,
    String? artworkUrl,
    DateTime? startedAt,
    DateTime? endsAt,
  }) => Track(
    artist: artist ?? this.artist,
    title: title ?? this.title,
    album: album ?? this.album,
    artworkUrl: artworkUrl ?? this.artworkUrl,
    startedAt: startedAt ?? this.startedAt,
    endsAt: endsAt ?? this.endsAt,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'artist': artist,
    'title': title,
    'album': album,
    'artworkUrl': artworkUrl,
    'startedAt': startedAt?.toIso8601String(),
    'endsAt': endsAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Track &&
      other.artist == artist &&
      other.title == title &&
      other.album == album &&
      other.artworkUrl == artworkUrl &&
      other.startedAt == startedAt &&
      other.endsAt == endsAt;

  @override
  int get hashCode =>
      Object.hash(artist, title, album, artworkUrl, startedAt, endsAt);

  @override
  String toString() => 'Track($artist - $title)';
}

String? _string(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
