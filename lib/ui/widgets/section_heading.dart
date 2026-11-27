import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Abschnittsueberschrift wie `h1` der Web-App: Syncopate 700, 25 px,
/// Grossbuchstaben, Zeilenhoehe 1,4, 20 dp Abstand nach unten.
///
/// Auf schmalen Geraeten oder bei grosser Systemschrift bricht der Text um,
/// statt abgeschnitten zu werden. [trailing] steht rechts (z. B. Aktion
/// "Exportieren"). Fuer Screenreader ist das Element als Ueberschrift der
/// Ebene 1 markiert (Seitentitel, im Web `h1`). Passt das laengste Wort nicht
/// in die Zeile (z. B. "EINSTELLUNGEN" bei 320 dp), wird die Schrift so weit
/// verkleinert, dass kein Wort mitten im Wort umbricht.
class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.text, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: LinefmSpace.gutter),
    this.style,
    this.headingLevel = 1,
  });

  /// Ebene fuer Screenreader (1 = Seitentitel).
  final int headingLevel;

  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  /// Optional abweichender Stil (Farbe, Groesse).
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LinefmColors>()!;
    final base = LinefmText.sectionHeading.copyWith(color: colors.text);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
    );
  }
}

/// Verkleinert [style] so, dass das laengste Wort von [text] in [maxWidth]
/// passt. Ist genug Platz, bleibt der Stil unveraendert.
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
