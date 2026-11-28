import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/linefm_sheet.dart';
import 'package:material_ui/material_ui.dart';

/// Ein Eintrag im "Song oeffnen in ..."-Sheet.
class MusicLinkItem {
  const MusicLinkItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.onOpen,
  });

  /// Stabiler Schluessel (Tests): `apple`, `spotify`, `youtube`.
  final String key;
  final String label;
  final FaIconData icon;
  final Future<void> Function() onOpen;
}

/// Inhalt des Sheets: Titel plus eine Zeile je Musikdienst. Rein
/// darstellend, die Texte kommen vom Aufrufer.
class MusicLinksSheet extends StatelessWidget {
  const MusicLinksSheet({
    super.key,
    required this.title,
    required this.items,
    required this.onSelected,
  });

  final String title;
  final List<MusicLinkItem> items;

  /// Wird mit dem gewaehlten Eintrag aufgerufen (der Aufrufer schliesst das
  /// Sheet und oeffnet den Link).
  final void Function(MusicLinkItem item) onSelected;

  @override
  Widget build(BuildContext context) => LinefmSheetBody(
    title: title,
    rows: <Widget>[
      for (final item in items)
        LinefmSheetRow(
          leading: FaIcon(item.icon, size: 22),
          label: item.label,
          trailing: FaIcon(
            FontAwesomeIcons.arrowUpRightFromSquare,
            size: 14,
            color: context.linefm.muted,
          ),
          onTap: () => onSelected(item),
        ),
    ],
  );
}

/// Zeigt das Sheet. Der Aufrufer faengt Fehler in [MusicLinkItem.onOpen].
Future<void> showMusicLinksSheet(
  BuildContext context, {
  required String title,
  required List<MusicLinkItem> items,
}) {
  return showLinefmSheet(
    context,
    label: title,
    builder: (sheetContext) => MusicLinksSheet(
      title: title,
      items: items,
      onSelected: (item) {
        Navigator.of(sheetContext).pop();
        item.onOpen();
      },
    ),
  );
}
