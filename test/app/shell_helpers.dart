import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/ui/widgets/quiet_tooltip.dart';
import 'package:material_ui/material_ui.dart';

const noAutoplay = AppSettings(autoplay: false);

/// Knopf mit [QuietTooltip] (der Material-Finder `byTooltip` kennt nur
/// Tooltips mit Semantik).
Finder byQuietTooltip(String message) =>
    find.byWidgetPredicate((w) => w is QuietTooltip && w.message == message);

/// Drueckt [count] mal (Shift+)Tab und liefert je Schritt den Shell-Bereich
/// des fokussierten Elements (1 Header ... 5 Navigation, 0 ausserhalb).
Future<List<int>> tabRegions(
  WidgetTester tester,
  LogicalKeyboardKey key,
  int count, {
  bool shift = false,
}) async {
  final regions = <int>[];
  for (var i = 0; i < count; i++) {
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump(const Duration(milliseconds: 50));
    regions.add(regionOf(FocusManager.instance.primaryFocus?.context));
  }
  return regions;
}

/// Aeusserste [FocusTraversalOrder] ueber [context] = Bereich der Shell.
int regionOf(BuildContext? context) {
  if (context == null) return 0;
  var region = 0;
  context.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is FocusTraversalOrder) {
      final order = widget.order;
      if (order is NumericFocusOrder) region = order.order.toInt();
    }
    return true;
  });
  return region;
}

/// Erster Durchlauf bis zum Umbruch (Bereich faellt bzw. steigt wieder).
List<int> untilWrap(List<int> regions, {bool reverse = false}) {
  final out = <int>[];
  for (final r in regions) {
    if (out.isNotEmpty && (reverse ? r > out.last : r < out.last)) break;
    out.add(r);
  }
  return out;
}

bool isAscending(List<int> values) {
  for (var i = 1; i < values.length; i++) {
    if (values[i] < values[i - 1]) return false;
  }
  return true;
}
