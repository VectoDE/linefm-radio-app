import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Abschnittsueberschrift wie `h1` der Web-App: Syncopate 700, 25 px,
/// Grossbuchstaben, Zeilenhoehe 1,4, 20 dp Abstand nach unten.
///
/// Auf schmalen Geraeten oder bei grosser Systemschrift bricht der Text um,
/// statt abgeschnitten zu werden. [trailing] steht rechts (z. B. Aktion
/// "Exportieren"). Fuer Screenreader ist das Element als Ueberschrift
/// markiert (Navigation per Ueberschriften-Rotor).
class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.text, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 20),
    this.style,
  });

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
              child: Text(text.toUpperCase(), style: base.merge(style)),
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
