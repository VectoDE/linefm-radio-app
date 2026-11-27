import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Section heading like `h1` of the web app: Syncopate 700, 25 px,
/// uppercase, line height 1.4, 20 dp spacing below.
///
/// On narrow devices or with a large system font the text wraps instead of
/// being cut off. [trailing] sits on the right (e.g. action
/// "Export"). For screen readers the element is marked as a level 1
/// heading (page title, `h1` on the web). If the longest word does not fit
/// in the line (e.g. "EINSTELLUNGEN" at 320 dp), the font is shrunk until
/// no word breaks in the middle.
class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.text, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: LinefmSpace.md),
    this.style,
    this.headingLevel = 1,
  });

  /// Level for screen readers (1 = page title).
  final int headingLevel;

  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  /// Optional differing style (color, size).
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LinefmColors>()!;
    final base = LinefmText.sectionHeading.copyWith(color: colors.text);
    // Fixed minimum height: a heading with trailing buttons (favorites,
    // history) sits at the same height as one without (stations, settings).
    return Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: LinefmMetrics.minTarget),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                headingLevel: headingLevel,
                container: true,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final upper = text.toUpperCase();
                    final merged = base.merge(style);
                    return Text(
                      upper,
                      style: fitLongestWord(
                        upper,
                        merged,
                        box.maxWidth,
                        MediaQuery.textScalerOf(context),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: LinefmSpace.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Shrinks [style] so that the longest word of [text] fits in [maxWidth].
/// If there is enough room, the style stays unchanged.
TextStyle fitLongestWord(
  String text,
  TextStyle style,
  double maxWidth,
  TextScaler scaler,
) {
  if (!maxWidth.isFinite || maxWidth <= 0) return style;
  var widest = 0.0;
  for (final word in text.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  if (widest <= maxWidth) return style;
  final size = style.fontSize ?? 14;
  return style.copyWith(fontSize: size * (maxWidth / widest) * 0.98);
}
