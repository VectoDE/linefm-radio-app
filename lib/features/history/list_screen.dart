import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/section_heading.dart';
import 'package:material_ui/material_ui.dart';

/// Gemeinsamer Rahmen fuer Verlauf und Favoriten: scrollbare Liste mit
/// Ueberschrift als erstem Eintrag, seitlichem Rand wie die Web-App
/// (`clamp(22px, 6vw, 88px)`) und auf breiten Fenstern auf [maxContentWidth]
/// begrenzter, zentrierter Inhaltsbreite. Die Liste selbst nutzt die volle
/// Breite, damit Mausrad und Wischen ueberall greifen.
///
/// [bottomInset] haelt Platz fuer Mini-Player und Navigation frei (Web: 170).
/// Optional zieht [onRefresh] per Pull-to-refresh nach.
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
    this.maxContentWidth = 760,
  });

  final String title;
  final Widget? trailing;

  /// Zusaetzlich unter der Ueberschrift (z. B. Hinweis), optional.
  final Widget? header;

  /// Ersetzt die Zeilen, wenn [itemCount] 0 ist.
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
        final base = (width * 0.06).clamp(22.0, 88.0);
        final centered = (width - maxContentWidth) / 2;
        final side = centered > base ? centered : base;
        final empty = itemCount == 0 && emptyState != null;
        final extra = header == null ? 0 : 1;
        final count = 1 + extra + (empty ? 1 : itemCount);

        final list = ListView.builder(
          // Immer scrollbar, damit Pull-to-refresh auch bei kurzer Liste geht.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(side, 8, side, bottomInset),
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
