import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/ui/theme/station_style.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Kuerzel eines Senders wie in der Web-App: Name ohne "LineFM" und "+",
/// erste drei Zeichen, gross ("LineFM +MAIN" wird "MAI", "FobFM" "FOB").
String stationInitials(String displayName) {
  final stripped = displayName.replaceFirst(
    RegExp(r'^LineFM\s*\+?', caseSensitive: false),
    '',
  );
  final source = stripped.isEmpty ? displayName : stripped;
  final end = source.length < 3 ? source.length : 3;
  return source.substring(0, end).toUpperCase();
}

/// Senderlogo auf Senderfarben-Verlauf. Bis das Logo geladen ist (oder wenn
/// es fehlt) steht das Kuerzel da; das Logo blendet in 200 ms ein.
///
/// Das Logo ist rein dekorativ (Name steht daneben), deshalb ohne Semantik.
class StationArt extends StatelessWidget {
  const StationArt({
    super.key,
    required this.station,
    this.size = 72,
    this.borderRadius = LinefmMetrics.radiusLogo,
  });

  final Station station;
  final double size;

  /// Eckenradius, Standard [LinefmMetrics.radiusLogo].
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    // Kuerzel-Groesse 11 bei 48 dp, linear mitwachsend.
    final fontSize = size * 11 / 48;
    final onColor = StationStyle.onStation(station.color, large: true);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: StationStyle.artGradient(station.color),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Center(
                  child: Opacity(
                    opacity: 0.8,
                    child: Text(
                      stationInitials(station.displayName),
                      style: TextStyle(
                        fontFamily: LinefmFonts.brand,
                        fontWeight: FontWeight.w700,
                        fontSize: fontSize,
                        color: onColor,
                      ),
                    ),
                  ),
                ),
                Image.asset(
                  station.logoAsset,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  filterQuality: FilterQuality.medium,
                  frameBuilder: (context, child, frame, sync) => sync
                      ? child
                      : AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: LinefmMetrics.fast,
                          child: child,
                        ),
                  errorBuilder: (context, error, stack) =>
                      const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
