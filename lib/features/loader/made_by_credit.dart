import 'package:flutter/gestures.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Zeile "Made by Tim Hauke with ♥" (in allen Sprachen gleich).
///
/// Der Autorenname ist hervorgehoben und mit [onAuthorTap] ein Link, das
/// Herz ist farbig. Im Ladebildschirm ist die Zeile nicht bedienbar und
/// bekommt deshalb keinen Link. Das Herz ist wie in der
/// Web-App ein Symbol (dort Font Awesome) und kein Textzeichen, weil weder
/// Poppins noch ein gebuendelter Schrift-Ersatz auf Web das Zeichen U+2665
/// enthaelt. Screenreader lesen den vollen Wortlaut aus
/// [AppLocalizations.creditsMadeBy].
class MadeByCredit extends StatefulWidget {
  const MadeByCredit({
    super.key,
    required this.style,
    required this.authorColor,
    required this.heartColor,
    this.textAlign = TextAlign.start,
    this.onAuthorTap,
  });

  final TextStyle style;
  final Color authorColor;
  final Color heartColor;
  final TextAlign textAlign;
  final VoidCallback? onAuthorTap;

  @override
  State<MadeByCredit> createState() => _MadeByCreditState();
}

class _MadeByCreditState extends State<MadeByCredit> {
  TapGestureRecognizer? _recognizer;

  @override
  void dispose() {
    _recognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _recognizer?.dispose();
    final onTap = widget.onAuthorTap;
    _recognizer = onTap == null
        ? null
        : (TapGestureRecognizer()..onTap = onTap);
    final style = widget.style;
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
              recognizer: _recognizer,
              style: TextStyle(
                color: widget.authorColor,
                fontWeight: FontWeight.w600,
                decoration: _recognizer == null
                    ? null
                    : TextDecoration.underline,
              ),
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
                    color: widget.heartColor,
                  ),
                ),
              ),
          ],
        ),
        textAlign: widget.textAlign,
      ),
    );
  }
}
