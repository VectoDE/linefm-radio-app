import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/ui/widgets/station_art.dart';
import 'package:material_ui/material_ui.dart';

/// Cover mit Rueckfallkette Cover, Senderlogo, Kuerzel. Platzhalter, P04.
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.station,
    this.url,
    this.size = 72,
  });

  final Station station;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) =>
      StationArt(station: station, size: size);
}
