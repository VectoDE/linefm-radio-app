import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/legal/legal_screen.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// Shared layout of the consent dialogs: title, body text, privacy link and
/// two equal buttons (decline pops `false`, allow pops `true`), nothing
/// preselected.
class ConsentDialogFrame extends StatelessWidget {
  const ConsentDialogFrame({
    required this.title,
    required this.text,
    super.key,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    return NamedDialog(
      label: title,
      child: AlertDialog(
        semanticLabel: title,
        scrollable: true,
        title: Semantics(header: true, child: Text(title)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                text,
                style: LinefmText.listTitle.copyWith(
                  color: c.text,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: LinefmSpace.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => openLegal(context, LegalKind.privacy),
                  child: Text(l10n.consentPrivacyLink),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          LinefmSpace.xl,
          0,
          LinefmSpace.xl,
          LinefmSpace.gutter,
        ),
        actions: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.consentDecline),
                ),
              ),
              const SizedBox(width: LinefmSpace.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.consentAllow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
