import 'package:audio_service/audio_service.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';

/// Liefert das Bild eines Senders im Auto-Menue.
typedef StationArtUri = Uri Function(Station station);

/// Ordner des Auto-Menues (Android Auto und CarPlay, Entscheidung 49).
enum AutoMenuSection { favoriteStations, stations, recent }

/// Ein Ordner des Auto-Menues mit seinen Sendern. Plattformneutral, damit
/// Android Auto ([BrowseTree.children]) und CarPlay (Kanal
/// `de.linefm.app/carplay`, P17) dieselben drei Eintraege zeigen.
class AutoMenuFolder {
  const AutoMenuFolder({
    required this.section,
    required this.title,
    required this.stations,
  });

  final AutoMenuSection section;
  final String title;
  final List<Station> stations;

  /// Knoten-ID im Browse-Tree.
  String get id => switch (section) {
    AutoMenuSection.favoriteStations => BrowseTree.favoriteStationsId,
    AutoMenuSection.stations => BrowseTree.stationsId,
    AutoMenuSection.recent => BrowseTree.recentId,
  };

  /// Fuer den CarPlay-Kanal: `{id, title, stations: [{id, slug, title,
  /// logoAsset, logoUrl}]}`.
  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'title': title,
    'stations': <Map<String, String>>[
      for (final s in stations)
        <String, String>{
          'id': s.id,
          'slug': s.slug,
          'title': s.displayName,
          'logoAsset': s.logoAsset,
          'logoUrl': s.logoUrl,
        },
    ],
  };
}

/// Ordnernamen des Auto-Menues (lokalisiert vom Aufrufer).
class AutoMenuTitles {
  const AutoMenuTitles({
    this.favoriteStations = 'Favoriten-Sender',
    this.stations = 'Sender',
    this.recent = 'Zuletzt gehört',
  });

  final String favoriteStations;
  final String stations;
  final String recent;
}

/// Android-Auto-Browse-Tree (Spec 2.2, Issue #42): Die Wurzel zeigt immer
/// drei Ordner in fester Reihenfolge: Favoriten-Sender, Sender, Zuletzt
/// gehoert. Dazu Suche im Sendernamen.
class BrowseTree {
  const BrowseTree._();

  static const String rootId = AudioService.browsableRootId;
  static const String favoriteStationsId = 'favorite_stations';
  static const String stationsId = 'stations';

  /// Entspricht [AudioService.recentRootId]: Android nutzt denselben Knoten
  /// fuer "Zuletzt gespielt" (Fortsetzen nach Neustart).
  static const String recentId = AudioService.recentRootId;

  /// Inhaltsstil-Hinweise fuer Android Auto (androidx.media.utils
  /// `MediaConstants`): 1 = Liste, 2 = Raster.
  static const String contentStylePlayableHint =
      'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT';
  static const String contentStyleBrowsableHint =
      'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT';
  static const int contentStyleList = 1;
  static const int contentStyleGrid = 2;

  /// Paket der App fuer `android.resource://`-Bilder.
  static const String androidPackage = 'de.linefm.app';

  /// Senderlogo als gebuendelte Android-Ressource. Android Auto zeigt im
  /// Menue nur lokale Bilder (`content://` oder `android.resource://`), keine
  /// Web-Adressen. Die Drawables `auto_station_<slug>` liegen in
  /// `android/app/src/main/res/drawable-nodpi/` und sind in `keep.xml` vor dem
  /// Ressourcen-Schrumpfen geschuetzt.
  static Uri androidResourceArt(Station station) => Uri.parse(
    'android.resource://$androidPackage/drawable/${androidDrawableName(station)}',
  );

  /// Name des Drawables eines Senders (nur Kleinbuchstaben und Ziffern).
  static String androidDrawableName(Station station) =>
      'auto_station_${station.slug.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '')}';

  /// Senderlogo aus dem Netz (iOS, Web, Benachrichtigung).
  static Uri remoteArt(Station station) => Uri.parse(station.logoUrl);

  /// Die drei Ordner des Auto-Menues. [favorites] sind die gemerkten Sender
  /// (Reihenfolge der Senderliste), [recent] die zuletzt gehoerte Station.
  static List<AutoMenuFolder> menu({
    List<Station> favorites = const <Station>[],
    Station? recent,
    AutoMenuTitles titles = const AutoMenuTitles(),
  }) => <AutoMenuFolder>[
    AutoMenuFolder(
      section: AutoMenuSection.favoriteStations,
      title: titles.favoriteStations,
      stations: List<Station>.unmodifiable(favorites),
    ),
    AutoMenuFolder(
      section: AutoMenuSection.stations,
      title: titles.stations,
      stations: stationsCatalog,
    ),
    AutoMenuFolder(
      section: AutoMenuSection.recent,
      title: titles.recent,
      stations: <Station>[?recent],
    ),
  ];

  /// Kinder eines Knotens. Unbekannte Knoten liefern eine leere Liste.
  static List<MediaItem> children(
    String parentId, {
    List<Station> favorites = const <Station>[],
    Station? recent,
    AutoMenuTitles titles = const AutoMenuTitles(),
    StationArtUri art = remoteArt,
  }) {
    final folders = menu(favorites: favorites, recent: recent, titles: titles);
    if (parentId == rootId) {
      return <MediaItem>[for (final f in folders) folderItem(f)];
    }
    for (final f in folders) {
      if (f.id == parentId) {
        return <MediaItem>[
          for (final s in f.stations) stationItem(s, art: art(s)),
        ];
      }
    }
    return const <MediaItem>[];
  }

  /// Ordner-Eintrag (nicht abspielbar); Sender darin als Raster.
  static MediaItem folderItem(AutoMenuFolder folder) => MediaItem(
    id: folder.id,
    title: folder.title,
    playable: false,
    extras: const <String, dynamic>{
      contentStylePlayableHint: contentStyleGrid,
      contentStyleBrowsableHint: contentStyleList,
    },
  );

  /// Sender, deren Name oder Slug [query] enthaelt (Gross-/Kleinschreibung
  /// egal, "LineFM +" wird bei Bedarf ignoriert). Leere Suche = alle.
  static List<MediaItem> search(
    String query, {
    StationArtUri art = remoteArt,
  }) => <MediaItem>[
    for (final s in searchStations(query)) stationItem(s, art: art(s)),
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

  /// MediaItem einer Station, optional mit aktuellem Titel. Ohne Cover des
  /// Titels zeigt [art] das Senderbild (Standard: Logo aus dem Netz).
  static MediaItem stationItem(Station station, {Track? track, Uri? art}) {
    final hasTrack =
        track != null && (track.title.isNotEmpty || track.artist.isNotEmpty);
    final cover = hasTrack ? track.artworkUrl : null;
    return MediaItem(
      id: station.slug,
      title: hasTrack ? track.title : station.displayName,
      artist: hasTrack ? track.artist : null,
      album: station.displayName,
      displayTitle: hasTrack ? track.title : station.displayName,
      displaySubtitle: hasTrack ? track.artist : null,
      displayDescription: station.displayName,
      artUri: cover != null && cover.isNotEmpty
          ? Uri.parse(cover)
          : (art ?? remoteArt(station)),
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
