import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Zeile "Made by .jaybelife with ♥" (in allen Sprachen gleich).
///
/// Der Autorenname ist hervorgehoben, das Herz farbig. Das Herz ist wie in der
/// Web-App ein Symbol (dort Font Awesome) und kein Textzeichen, weil weder
/// Poppins noch ein gebuendelter Schrift-Ersatz auf Web das Zeichen U+2665
/// enthaelt. Screenreader lesen den vollen Wortlaut aus
/// [AppLocalizations.creditsMadeBy].
class MadeByCredit extends StatelessWidget {
  const MadeByCredit({
    super.key,
    required this.style,
    required this.authorColor,
    required this.heartColor,
    this.textAlign = TextAlign.start,
  });

  final TextStyle style;
  final Color authorColor;
  final Color heartColor;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // " with ♥" -> " with " + Symbol; ohne Herz im Text bleibt der Rest stehen.
    final tail = l10n.creditsMadeByTail;
    final heartAt = tail.lastIndexOf('♥');
    final tailText = heartAt < 0 ? tail : tail.substring(0, heartAt);
    final fontSize = style.fontSize ?? 12;
    return Semantics(
      label: l10n.creditsMadeBy,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: style,
          children: <InlineSpan>[
            TextSpan(text: l10n.creditsMadeByLead),
            TextSpan(
              text: l10n.creditsMadeByAuthor,
              style: TextStyle(color: authorColor, fontWeight: FontWeight.w600),
            ),
            TextSpan(text: tailText),
            if (heartAt >= 0)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Icon(
                    Icons.favorite,
                    size: fontSize + 1,
                    color: heartColor,
                  ),
                ),
              ),
          ],
        ),
        textAlign: textAlign,
      ),
    );
  }
}
