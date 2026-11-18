import 'package:linefm_radio/domain/station.dart';
import 'package:material_ui/material_ui.dart';

/// Senderlogo mit Kuerzel-Platzhalter. Platzhalter, P04.
class StationArt extends StatelessWidget {
  const StationArt({super.key, required this.station, this.size = 72});

  final Station station;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    station.logoAsset,
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
}
