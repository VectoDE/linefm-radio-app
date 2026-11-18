import 'package:material_ui/material_ui.dart';

/// Fensterklassen (Spec 4.3).
enum WindowClass {
  /// Unter 600 dp.
  compact,

  /// 600 bis 839 dp.
  medium,

  /// Ab 840 dp.
  expanded;

  static WindowClass fromWidth(double width) {
    if (width < 600) return WindowClass.compact;
    if (width < 840) return WindowClass.medium;
    return WindowClass.expanded;
  }

  static WindowClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);
}
