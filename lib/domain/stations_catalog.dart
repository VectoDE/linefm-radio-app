import 'dart:ui' show Color;

import 'package:linefm_radio/domain/station.dart';

// Die 6 Sender, fest im Code (Entscheidung 7). Quelle: streams.json.
const List<Station> stationsCatalog = <Station>[
  Station(
    id: '1',
    slug: 'linefm',
    displayName: 'LineFM +MAIN',
    color: Color(0xFF4B4B7D),
    logoAsset: 'assets/images/stations/main.png',
    logoUrl: 'https://cdn.linefm.de/images/icons/main.png',
    fallbackStreamUrl: 'https://stream.laut.fm/linefm',
  ),
  Station(
    id: '2',
    slug: 'linefmrap',
    displayName: 'LineFM +RAP',
    color: Color(0xFFFF0084),
    logoAsset: 'assets/images/stations/rap.png',
    logoUrl: 'https://cdn.linefm.de/images/icons/rap.png',
    fallbackStreamUrl: 'https://stream.laut.fm/linefmrap',
  ),
  Station(
    id: '3',
    slug: 'linefmgaming',
    displayName: 'LineFM +GAMING',
    color: Color(0xFF4BBD71),
    logoAsset: 'assets/images/stations/gaming.png',
    logoUrl: 'https://cdn.linefm.de/images/icons/gaming.png',
    fallbackStreamUrl: 'https://stream.laut.fm/linefmgaming',
  ),
  Station(
    id: '4',
    slug: 'linefmlofi',
    displayName: 'LineFM +LOFI',
    color: Color(0xFF546E7A),
    logoAsset: 'assets/images/stations/lofi.png',
    logoUrl: 'https://cdn.linefm.de/images/icons/lofi.png',
    fallbackStreamUrl: 'https://stream.laut.fm/linefmlofi',
  ),
  Station(
    id: '5',
    slug: 'radio3fm',
    displayName: 'Radio3FM',
    color: Color(0xFF177D29),
    logoAsset: 'assets/images/stations/radio3fm.png',
    logoUrl: 'https://cdn.linefm.de/images/icons/radio3fm.png',
    fallbackStreamUrl: 'https://stream.laut.fm/radio3fm',
  ),
  Station(
    id: '6',
    slug: 'fobfm',
    displayName: 'FobFM',
    color: Color(0xFF04FFF7),
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
