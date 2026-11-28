part of 'itunes_artwork.dart';

class ArtworkResult {
  const ArtworkResult({this.artworkUrl, this.trackViewUrl});

  /// 600x600-Cover.
  final String? artworkUrl;

  /// Apple-Music-Link des Treffers.
  final String? trackViewUrl;

  Map<String, Object?> toJson() => <String, Object?>{
    if (artworkUrl != null) 'a': artworkUrl,
    if (trackViewUrl != null) 'v': trackViewUrl,
  };

  static ArtworkResult? fromJson(Object? json) {
    if (json is! Map) return null;
    final a = json['a'];
    final v = json['v'];
    return ArtworkResult(
      artworkUrl: a is String ? a : null,
      trackViewUrl: v is String ? v : null,
    );
  }
}

/// iTunes-Cover-Lookup mit Drosselung und Cache (Spec 3.3).
abstract interface class ArtworkService {
  /// `null` = kein Cover gefunden (Aufrufer faellt auf Senderlogo bzw.
  /// Kuerzel-Kachel zurueck).
  Future<ArtworkResult?> lookup(Track track, {bool priority = false});
}

/// Ohne iTunes-Suche: nur ein Cover, das die laut.fm-API schon mitliefert
/// (Einstellung "Cover laden" aus).
class ApiCoverOnlyArtworkService implements ArtworkService {
  const ApiCoverOnlyArtworkService();

  @override
  Future<ArtworkResult?> lookup(Track track, {bool priority = false}) async {
    final cover = track.artworkUrl;
    return cover == null || cover.isEmpty
        ? null
        : ArtworkResult(artworkUrl: cover);
  }
}

/// Persistenter Speicher fuer den Cover-Cache (JSON-Text). Passt zu
/// `PrefsStore.readCoverCache`/`writeCoverCache`, z. B.:
/// `CoverCacheStore(read: prefs.readCoverCache, write: prefs.writeCoverCache)`.
class CoverCacheStore {
  const CoverCacheStore({required this.read, required this.write});

  final String? Function() read;
  final Future<void> Function(String json) write;
}

class _CacheItem {
  const _CacheItem(this.result, this.expiresAt);

  /// `null` = Fehltreffer (negativ gecacht).
  final ArtworkResult? result;
  final DateTime expiresAt;
}

class _Job {
  _Job(this.key, this.track);

  final String key;
  final Track track;
  final Completer<ArtworkResult?> completer = Completer<ArtworkResult?>();
}
