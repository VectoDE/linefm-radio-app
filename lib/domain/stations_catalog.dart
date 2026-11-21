import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';

// Die 6 Sender, fest im Code (Entscheidung 7). Quelle: streams.json.
const List<Station> stationsCatalog = <Station>[
  Station(
    id: '1',
    slug: 'linefm',
    displayName: 'LineFM +MAIN',
    color: LinefmStationColors.main,
    logoAsset: 'assets/images/stations/main.png',
    logoUrl: 'https://cdn.linefm.de/images/icons/main.png',
    fallbackStreamUrl: 'https://stream.laut.fm/linefm',
  ),
  Station(
    id: '2',
    slug: 'linefmrap',
    displayName: 'LineFM +RAP',
    color: LinefmStationColors.rap,
    logoAsset: 'assets/images/stations/rap.png',
    logoUrl: 'https://cdn.linefm.de/images/icons/rap.png',
    fallbackStreamUrl: 'https://stream.laut.fm/linefmrap',
  ),
  Station(
    id: '3',
    slug: 'linefmgaming',
    displayName: 'LineFM +GAMING',
    color: LinefmStationColors.gaming,
    logoAsset: 'assets/images/stations/gaming.png',
    logoUrl: 'https://cdn.linefm.de/images/icons/gaming.png',
    fallbackStreamUrl: 'https://stream.laut.fm/linefmgaming',
  ),
  Station(
    id: '4',
    slug: 'linefmlofi',
    displayName: 'LineFM +LOFI',
    color: LinefmStationColors.lofi,
    logoAsset: 'assets/images/stations/lofi.png',
    logoUrl: 'https://cdn.linefm.de/images/icons/lofi.png',
    fallbackStreamUrl: 'https://stream.laut.fm/linefmlofi',
  ),
  Station(
    id: '5',
    slug: 'radio3fm',
    displayName: 'Radio3FM',
    color: LinefmStationColors.radio3fm,
    logoAsset: 'assets/images/stations/radio3fm.png',
    logoUrl: 'https://cdn.linefm.de/images/icons/radio3fm.png',
    fallbackStreamUrl: 'https://stream.laut.fm/radio3fm',
  ),
  Station(
    id: '6',
    slug: 'fobfm',
    displayName: 'FobFM',
    color: LinefmStationColors.fobfm,
    logoAsset: 'assets/images/stations/fobfm.png',
    logoUrl: 'https://cdn.linefm.de/images/icons/fobfm.png',
    fallbackStreamUrl: 'https://stream.laut.fm/fobfm',
  ),
];

Station? stationBySlug(String slug) {
  for (final s in stationsCatalog) {
    if (s.slug == slug) return s;
  }
  return null;
}
