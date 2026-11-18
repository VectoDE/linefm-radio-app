import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';

/// Teilen, Export, Musikdienst-Links (Spec 2.2). Implementierung: P21.
abstract interface class ShareService {
  Future<void> shareSong(Station station, Track track);

  Future<void> exportFavorites(List<Favorite> favorites, ExportFormat format);

  Future<void> openUrl(Uri uri);
}

class NoopShareService implements ShareService {
  const NoopShareService();

  @override
  Future<void> shareSong(Station station, Track track) async {}

  @override
  Future<void> exportFavorites(
    List<Favorite> favorites,
    ExportFormat format,
  ) async {}

  @override
  Future<void> openUrl(Uri uri) async {}
}
