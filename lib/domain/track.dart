class Track {
  const Track({
    required this.artist,
    required this.title,
    this.album,
    this.artworkUrl,
    this.startedAt,
    this.endsAt,
  });

  final String artist;
  final String title;
  final String? album;
  final String? artworkUrl;
  final DateTime? startedAt;
  final DateTime? endsAt;
}
