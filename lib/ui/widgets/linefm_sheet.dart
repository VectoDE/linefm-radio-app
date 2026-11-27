import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
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
