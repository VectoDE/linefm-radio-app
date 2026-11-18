import 'package:audio_service/audio_service.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';

/// Android-Auto-Browse-Tree (Spec 2.2): Wurzel mit "stations" und "recent".
class BrowseTree {
  const BrowseTree._();

  static const String rootId = AudioService.browsableRootId;
  static const String stationsId = 'stations';
  static const String recentId = 'recent';

  /// Stub: nur die Senderliste, "recent" folgt in P10.
  static List<MediaItem> children(String parentId) {
    if (parentId == rootId || parentId == stationsId) {
      return <MediaItem>[
        for (final s in stationsCatalog)
          MediaItem(
            id: s.slug,
            title: s.displayName,
            artUri: Uri.parse(s.logoUrl),
            playable: true,
          ),
      ];
    }
    return const <MediaItem>[];
  }
}
