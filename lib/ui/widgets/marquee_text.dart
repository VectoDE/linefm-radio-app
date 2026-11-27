import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Lauftext wie `setMarqueeText` der Web-App.
///
/// - Passt der Text in die Breite, steht er still (optional zentriert).
/// - Nur bei Ueberlaenge laeuft er als Endlosband mit einer Kopie und
///   [LinefmMetrics.marqueeGap] Abstand, ein Durchlauf dauert 18 s.
/// - [enabled] false (Einstellung "Lauftext") oder System-Einstellung
///   `disableAnimations` zeigen statisch mit Auslassungspunkten.
/// - Das Band blendet an den Raendern weich aus, Screenreader lesen den Text
///   genau einmal.
class MarqueeText extends StatelessWidget {
  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.enabled = true,
    this.textAlign = TextAlign.start,
    this.loopDuration = LinefmMetrics.marqueeLoop,
    this.gap = LinefmMetrics.marqueeGap,
    this.bandInset = 0,
  });

  final String text;
  final TextStyle? style;

  /// Wert der Einstellung "Lauftext fuer lange Titel".
  final bool enabled;

  /// Ausrichtung, solange der Text nicht ueberlaeuft.
  final TextAlign textAlign;

  final Duration loopDuration;
  final double gap;

  /// Seitlicher Innenabstand nur fuer das laufende Band: Es blendet dann
  /// innerhalb dieses Abstands aus statt an der Kante des Elternelements.
  /// Text, der passt, nutzt weiter die volle Breite.
  final double bandInset;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: effective),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final textWidth = painter.width;
        final height = painter.height;
        painter.dispose();
        final available = constraints.maxWidth;
        final overflows =
            available.isFinite && textWidth > available + 1 && text.isNotEmpty;
        if (!overflows || !enabled || reduce) {
          return Text(
            text,
            style: style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
          );
        }
        return Semantics(
          label: text,
          excludeSemantics: true,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: bandInset),
            child: SizedBox(
              height: height,
              child: _Band(
                text: text,
                style: style,
                cycle: textWidth + gap,
                gap: gap,
                duration: loopDuration,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Band extends StatefulWidget {
  const _Band({
    required this.text,
    required this.style,
    required this.cycle,
    required this.gap,
    required this.duration,
  });

  final String text;
  final TextStyle? style;
  final double cycle;
  final double gap;
  final Duration duration;

  @override
  State<_Band> createState() => _BandState();
}

class _BandState extends State<_Band> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void didUpdateWidget(_Band old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration) {
      _controller
        ..duration = widget.duration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = Text(
      widget.text,
      style: widget.style,
      maxLines: 1,
      softWrap: false,
    );
    return RepaintBoundary(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          colors: <Color>[
            LinefmPalette.clearWhite,
            LinefmPalette.paper,
            LinefmPalette.paper,
            LinefmPalette.clearWhite,
          ],
          stops: <double>[0, 0.04, 0.96, 1],
        ).createShader(rect),
        child: ClipRect(
          child: OverflowBox(
            alignment: AlignmentDirectional.centerStart,
            minWidth: 0,
            maxWidth: double.infinity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(-_controller.value * widget.cycle, 0),
                child: child,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  copy,
                  SizedBox(width: widget.gap),
                  copy,
                  SizedBox(width: widget.gap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
