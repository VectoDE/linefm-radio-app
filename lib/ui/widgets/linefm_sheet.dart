import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

/// Shows a LineFM bottom sheet with the shared look (surface, scrim, rounded
/// top, 520 px wide) and an accessible [label] via [NamedSheet].
Future<void> showLinefmSheet(
  BuildContext context, {
  required String label,
  required Widget Function(BuildContext sheetContext) builder,
}) {
  final colors = context.linefm;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: colors.surface,
    barrierColor: LinefmPalette.scrim,
    constraints: const BoxConstraints(maxWidth: 520),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(LinefmMetrics.radiusCover),
      ),
    ),
    builder: (sheetContext) =>
        NamedSheet(label: label, child: builder(sheetContext)),
  );
}

/// Content of a LineFM sheet: drag handle, [title] as header and [rows].
class LinefmSheetBody extends StatelessWidget {
  const LinefmSheetBody({super.key, required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

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
            ...rows,
          ],
        ),
      ),
    );
  }
}

/// One row of a LineFM sheet. Without [onTap] the row is plain, muted text.
/// [leading] (an icon) takes its color from the surrounding icon theme.
class LinefmSheetRow extends StatelessWidget {
  const LinefmSheetRow({
    super.key,
    required this.leading,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.linefm;
    final foreground = onTap == null ? colors.muted : colors.text;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: LinefmSpace.sm),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 32,
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(color: foreground),
                  child: leading,
                ),
              ),
            ),
            const SizedBox(width: LinefmSpace.lg),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge!
                    .copyWith(color: foreground),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        button: true,
        label: label,
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
          child: content,
        ),
      ),
    );
  }
}
