import 'package:audio_service/audio_service.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';

/// Android-Auto-Browse-Tree (Spec 2.2): Wurzel mit "stations" und
/// "recent" (zuletzt gehoerte Station), dazu Suche im Sendernamen.
class BrowseTree {
  const BrowseTree._();

  static const String rootId = AudioService.browsableRootId;
  static const String stationsId = 'stations';

  /// Entspricht [AudioService.recentRootId]: Android nutzt denselben Knoten
  /// fuer "Zuletzt gespielt" (Fortsetzen nach Neustart).
  static const String recentId = AudioService.recentRootId;

  /// Kinder eines Knotens. [recent] ist die zuletzt gespielte Station.
  /// [stationsTitle]/[recentTitle] sind die angezeigten Ordnernamen.
  static List<MediaItem> children(
    String parentId, {
    Station? recent,
    String stationsTitle = 'Stationen',
    String recentTitle = 'Zuletzt gehört',
  }) {
    switch (parentId) {
      case rootId:
        return <MediaItem>[
          MediaItem(id: stationsId, title: stationsTitle, playable: false),
          if (recent != null)
            MediaItem(id: recentId, title: recentTitle, playable: false),
        ];
      case stationsId:
        return <MediaItem>[for (final s in stationsCatalog) stationItem(s)];
      case recentId:
        return <MediaItem>[if (recent != null) stationItem(recent)];
    }
    return const <MediaItem>[];
  }

  /// Sender, deren Name oder Slug [query] enthaelt (Gross-/Kleinschreibung
  /// egal, "LineFM +" wird bei Bedarf ignoriert). Leere Suche = alle.
  static List<MediaItem> search(String query) => <MediaItem>[
    for (final s in searchStations(query)) stationItem(s),
  ];

  static List<Station> searchStations(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return stationsCatalog;
    return <Station>[
      for (final s in stationsCatalog)
        if (_normalize(s.displayName).contains(q) ||
            _normalize(s.slug).contains(q) ||
            q.contains(_normalize(_shortName(s))))
          s,
    ];
  }

  /// MediaItem einer Station, optional mit aktuellem Titel.
  static MediaItem stationItem(Station station, {Track? track}) {
    final hasTrack =
        track != null && (track.title.isNotEmpty || track.artist.isNotEmpty);
    return MediaItem(
      id: station.slug,
      title: hasTrack ? track.title : station.displayName,
      artist: hasTrack ? track.artist : null,
      album: station.displayName,
      displayTitle: hasTrack ? track.title : station.displayName,
      displaySubtitle: hasTrack ? track.artist : null,
      displayDescription: station.displayName,
      artUri: Uri.parse(
        hasTrack && track.artworkUrl != null && track.artworkUrl!.isNotEmpty
            ? track.artworkUrl!
            : station.logoUrl,
      ),
      playable: true,
      isLive: true,
      extras: <String, dynamic>{'stationId': station.id},
    );
  }

  static String _shortName(Station s) => s.displayName.replaceFirst(
    RegExp(r'^LineFM\s*\+', caseSensitive: false),
    '',
  );

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
