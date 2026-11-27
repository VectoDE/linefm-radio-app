import 'package:linefm_radio/ui/theme/breakpoints.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// One horizontal page margin for the header and every screen, so the
/// wordmark, headings and content share the same left edge.
abstract final class PageInsets {
  /// Margin on compact and medium windows.
  static const double compact = LinefmSpace.gutter;

  /// Margin on expanded windows (rail layout).
  static const double expanded = LinefmSpace.xl;

  /// Default readable width for list and text screens.
  static const double maxContentWidth = 720;

  /// Page margin for the current window class.
  static double gutter(BuildContext context) =>
      WindowClass.of(context) == WindowClass.expanded ? expanded : compact;

  /// Side margin for a content area of [width]: the page margin, or more when
  /// the content is centred at [maxWidth].
  static double side(
    BuildContext context,
    double width, {
    double maxWidth = maxContentWidth,
  }) {
    final base = gutter(context);
    final centered = (width - maxWidth) / 2;
    return centered > base ? centered : base;
  }
}
