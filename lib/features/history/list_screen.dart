import 'package:linefm_radio/ui/theme/page_insets.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/section_heading.dart';
import 'package:material_ui/material_ui.dart';

/// Shared frame for history and favorites: scrollable list with the
/// heading as first entry, side margin like the web app
/// (`clamp(22px, 6vw, 88px)`) and, on wide windows, centered content width
/// limited to [maxContentWidth]. The list itself uses the full width so
/// that mouse wheel and swipe work everywhere.
///
/// [bottomInset] keeps space free for mini player and navigation (web: 170).
/// Optionally [onRefresh] reloads via pull-to-refresh.
class ListScreen extends StatelessWidget {
  const ListScreen({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.trailing,
    this.header,
    this.emptyState,
    this.onRefresh,
    this.bottomInset = 170,
    this.maxContentWidth = PageInsets.maxContentWidth,
  });

  final String title;
  final Widget? trailing;

  /// Additionally below the heading (e.g. a notice), optional.
  final Widget? header;

  /// Replaces the rows when [itemCount] is 0.
  final Widget? emptyState;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Future<void> Function()? onRefresh;
  final double bottomInset;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final side = PageInsets.side(context, width, maxWidth: maxContentWidth);
        final empty = itemCount == 0 && emptyState != null;
        final extra = header == null ? 0 : 1;
        final count = 1 + extra + (empty ? 1 : itemCount);

        final list = ListView.builder(
          // Always scrollable so that pull-to-refresh also works with a short list.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            side,
            LinefmSpace.gutter,
            side,
            bottomInset,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            if (index == 0) {
              return SectionHeading(title, trailing: trailing);
            }
            if (header != null && index == 1) return header!;
            if (empty) return emptyState!;
            return itemBuilder(context, index - 1 - extra);
          },
        );

        if (onRefresh == null) return list;
        return RefreshIndicator(
          color: context.linefm.accent,
          backgroundColor: context.linefm.surfaceRaised,
          onRefresh: onRefresh!,
          child: list,
        );
      },
    );
  }
}
