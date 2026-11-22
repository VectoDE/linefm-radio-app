import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/legal/legal_screen.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// Soll der Speicher-Hinweis als Popup erscheinen? Nur in der App und auf dem
/// Desktop (nicht im Browser, dort steht der Banner) und solange er nicht
/// bestaetigt ist.
bool shouldShowStorageNoticeDialog({
  required PlatformInfo platform,
  required bool confirmed,
}) => !platform.isWeb && !confirmed;

/// Zeigt den Speicher-Hinweis als Popup. Ergebnis ist nur `true`: Das Popup
/// schliesst ausschliesslich ueber "Verstanden". Tipp neben das Popup,
/// Android-Zurueck (auch die Vorschau-Geste) und Esc schliessen es nicht, damit
/// die Bestaetigung nicht still ausbleibt und der Hinweis beim naechsten Start
/// wieder kaeme.
Future<bool?> showStorageNoticeDialog(BuildContext context) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const StorageNoticeDialog(),
);

/// Inhalt des Popups: Titel, Text mit "auf diesem Gerät", Link
/// "Datenschutz" und die Schaltflaeche "Verstanden".
class StorageNoticeDialog extends StatelessWidget {
  const StorageNoticeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    const targetStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(
        Size(LinefmMetrics.minTarget, LinefmMetrics.minTarget),
      ),
    );
    return PopScope(
      // Zurueck/Esc/Vorschau-Geste verwerfen: nur "Verstanden" schliesst.
      canPop: false,
      child: NamedDialog(
        label: l10n.storageNoticeTitle,
        child: AlertDialog(
          semanticLabel: l10n.storageNoticeTitle,
          // Bei 200 % Schrift scrollt der Inhalt, statt abgeschnitten zu werden.
          scrollable: true,
          title: Semantics(header: true, child: Text(l10n.storageNoticeTitle)),
          content: Text(
            l10n.storageNoticeBodyDevice,
            style: LinefmText.listTitle.copyWith(color: c.text, height: 1.55),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            LinefmSpace.xl,
            0,
            LinefmSpace.xl,
            LinefmSpace.gutter,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => openLegal(context, LegalKind.privacy),
              style: targetStyle,
              child: Text(l10n.storageNoticePrivacy),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: targetStyle,
              child: Text(l10n.storageNoticeDismiss),
            ),
          ],
        ),
      ),
    );
  }
}
