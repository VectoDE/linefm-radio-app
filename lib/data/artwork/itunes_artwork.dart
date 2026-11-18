import 'package:linefm_radio/domain/track.dart';

class ArtworkResult {
  const ArtworkResult({this.artworkUrl, this.trackViewUrl});

  /// 600x600-Cover.
  final String? artworkUrl;

  /// Apple-Music-Link des Treffers.
  final String? trackViewUrl;
}

/// iTunes-Cover-Lookup mit Drosselung und Cache (Spec 3.3). Stub, P03.
abstract interface class ArtworkService {
  Future<ArtworkResult?> lookup(Track track, {bool priority = false});
}

class NoopArtworkService implements ArtworkService {
  const NoopArtworkService();

  @override
  Future<ArtworkResult?> lookup(Track track, {bool priority = false}) async =>
      null;
}
