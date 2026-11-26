import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/linefm_sheet.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
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
  Widget build(BuildContext context) {
    final colors = context.linefm;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LinefmSpace.gutter,
          LinefmSpace.md,
          LinefmSpace.gutter,
          LinefmSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: ExcludeSemantics(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.line,
                    borderRadius: BorderRadius.circular(
                      LinefmMetrics.radiusPill,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: LinefmSpace.lg),
            Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: colors.text,
                ),
              ),
            ),
            const SizedBox(height: LinefmSpace.sm),
            for (final item in items)
              _MusicRow(item: item, onTap: () => onSelected(item)),
          ],
        ),
      ),
    );
  }
}

class _MusicRow extends StatelessWidget {
  const _MusicRow({required this.item, required this.onTap});

  final MusicLinkItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.linefm;
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        button: true,
        label: item.label,
        excludeSemantics: true,
        onTap: onTap,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        child: child,
      ),
      child: FocusRing(
        borderRadius: LinefmMetrics.radiusPopover,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LinefmMetrics.radiusPopover),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LinefmSpace.sm),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 32,
                    child: Center(
                      child: FaIcon(item.icon, size: 22, color: colors.text),
                    ),
                  ),
                  const SizedBox(width: LinefmSpace.lg),
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyLarge!
                          .copyWith(color: colors.text),
                    ),
                  ),
                  FaIcon(
                    FontAwesomeIcons.arrowUpRightFromSquare,
                    size: 14,
                    color: colors.muted,
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
