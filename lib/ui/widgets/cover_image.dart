import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/station_art.dart';
import 'package:material_ui/material_ui.dart';

/// Cover mit Rueckfallkette: Cover-URL, dann Senderlogo, dann Kuerzel
/// (`StationArt`). Waehrend des Ladens und bei Fehlern bleibt der Rueckfall
/// sichtbar, das Cover blendet in 250 ms darueber ein. Wechselt [url], wird
/// ohne Flackern ueberblendet (`gaplessPlayback`).
///
/// Web: `WebHtmlElementStrategy.fallback` laedt Bilder ohne CORS-Freigabe
/// (iTunes-CDN) ueber ein HTML-Element, statt mit leerer Flaeche zu scheitern.
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.station,
    this.url,
    this.size = 72,
    this.borderRadius,
    this.shadow = false,
    this.semanticLabel,
  });

  final Station station;

  /// Cover-URL (iTunes 600x600) oder null.
  final String? url;
  final double size;

  /// Standard: [LinefmMetrics.radiusLogo]. Player: 24 (Handy 16).
  final double? borderRadius;

  /// Cover-Schatten wie im Player (Spec 4.4).
  final bool shadow;

  /// Beschreibung fuer Screenreader. Null = dekorativ.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      borderRadius ?? LinefmMetrics.radiusLogo,
    );
    final colors = Theme.of(context).extension<LinefmColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (size * dpr).round();
    final cover = url;

    Widget child = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        StationArt(station: station, size: size, borderRadius: 0),
        if (cover != null && cover.isNotEmpty)
          Image.network(
            cover,
            key: ValueKey<String>(cover),
            fit: BoxFit.cover,
            cacheWidth: cacheSize,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            filterQuality: FilterQuality.medium,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            frameBuilder: (context, child, frame, sync) => sync
                ? child
                : AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: LinefmMetrics.medium,
                    curve: Curves.easeOut,
                    child: child,
                  ),
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
      ],
    );

    child = ClipRRect(borderRadius: radius, child: child);

    if (shadow) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: LinefmMetrics.coverShadows(colors, dark: dark),
        ),
        child: child,
      );
    }

    return Semantics(
      image: semanticLabel != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox.square(dimension: size, child: child),
    );
  }
}
