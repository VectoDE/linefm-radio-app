import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/ui/theme/station_style.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/marquee_text.dart';
import 'package:linefm_radio/ui/widgets/station_art.dart';
import 'package:material_ui/material_ui.dart';

/// Karte eines Senders (`.station-card` der Web-App).
///
/// - [grid] false: Zeile fuer Handy (Logo 72, mind. 90 hoch).
/// - [grid] true: Kachel ab 600 dp (Logo 76 oben mittig, mind. 196 hoch,
///   Name und Ticker zentriert).
/// - Verlauf 285 Grad aus 20 % Senderfarbe in `surface`, Rahmen 2 dp in
///   `background`, aktiv oder beim Ueberfahren in Senderfarbe (bei
///   Kontrastmangel aufgehellt, siehe `StationStyle.border`).
/// - Auf der aktiven Karte zeigen drei Balken, dass gespielt wird.
class StationCard extends StatefulWidget {
  const StationCard({
    super.key,
    required this.station,
    required this.semanticLabel,
    required this.onTap,
    this.ticker = '',
    this.active = false,
    this.playing = false,
    this.grid = false,
    this.marquee = true,
    this.onLongPress,
    this.longPressLabel,
  });

  final Station station;

  /// Ticker "Artist - Titel", leer solange unbekannt.
  final String ticker;

  /// Beschriftung fuer Screenreader (lokalisiert vom Aufrufer).
  final String semanticLabel;

  final bool active;
  final bool playing;
  final bool grid;

  /// Einstellung "Lauftext".
  final bool marquee;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Beschriftung der Long-Press-Aktion fuer Screenreader.
  final String? longPressLabel;

  @override
  State<StationCard> createState() => _StationCardState();
}

class _StationCardState extends State<StationCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.linefm;
    final station = widget.station;
    final accent = StationStyle.border(station.color, colors);
    final highlighted = widget.active || _hover;
    final radius = BorderRadius.circular(LinefmMetrics.radiusCard);
    final grid = widget.grid;
    final artSize = grid ? 76.0 : 72.0;

    final name = Text(
      station.displayName.toUpperCase(),
      maxLines: grid ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      textAlign: grid ? TextAlign.center : TextAlign.start,
      style: LinefmText.stationName(grid: grid).copyWith(color: colors.text),
    );
    final ticker = widget.ticker.isEmpty
        ? SizedBox(height: LinefmText.ticker.fontSize! * 1.4)
        : MarqueeText(
            widget.ticker,
            enabled: widget.marquee,
            textAlign: grid ? TextAlign.center : TextAlign.start,
            style: LinefmText.ticker.copyWith(color: colors.tickerText),
          );

    final copy = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: grid
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[name, const SizedBox(height: 7), ticker],
    );

    final Widget content = grid
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              StationArt(station: station, size: artSize),
              const SizedBox(height: 14),
              copy,
            ],
          )
        : Row(
            children: <Widget>[
              StationArt(station: station, size: artSize),
              const SizedBox(width: 13),
              Expanded(child: copy),
            ],
          );

    return Semantics(
      container: true,
      button: true,
      selected: widget.active,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onTap,
      customSemanticsActions:
          widget.onLongPress != null && widget.longPressLabel != null
          ? <CustomSemanticsAction, VoidCallback>{
              CustomSemanticsAction(label: widget.longPressLabel!):
                  widget.onLongPress!,
            }
          : null,
      child: FocusRing(
        borderRadius: LinefmMetrics.radiusCard,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: highlighted ? accent : colors.background,
              width: 2,
            ),
            gradient: StationStyle.cardGradient(station.color, colors),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onHover: (v) => setState(() => _hover = v),
              borderRadius: radius,
              child: Stack(
                children: <Widget>[
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: grid ? 192 : 86),
                    child: Padding(
                      padding: EdgeInsets.all(grid ? 16 : 10),
                      child: Align(
                        alignment: grid
                            ? Alignment.center
                            : Alignment.centerLeft,
                        child: content,
                      ),
                    ),
                  ),
                  if (widget.active && widget.playing)
                    Positioned(
                      top: grid ? 12 : 10,
                      right: grid ? 12 : 10,
                      child: _PlayingBars(color: accent),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Drei Balken im Wechsel, still bei `disableAnimations`.
class _PlayingBars extends StatefulWidget {
  const _PlayingBars({required this.color});

  final Color color;

  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 14,
        height: 14,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (var i = 0; i < 3; i++)
                Container(
                  width: 3,
                  height: 4 + 10 * _wave(_c.value + i / 3),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sinus 0 bis 1.
  double _wave(double t) {
    final x = (t % 1) * 2;
    return x < 1 ? x : 2 - x;
  }
}
