import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/features/history/icon_action.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Screenreader-Aktivierung des Umschalters "Song merken" (Herz je Zeile).
void main() {
  Future<void> pump(WidgetTester tester, {required bool initial}) async {
    var on = initial;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLinefmTheme(Brightness.light),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => IconAction(
              icon: on ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
              label: 'Song merken',
              toggled: on,
              onPressed: () => setState(() => on = !on),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Screenreader-Tap schaltet um, Zustand als Schalter', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, initial: false);

    final finder = find.semantics.byLabel('Song merken');
    expect(finder, findsOneWidget);
    var data = tester.getSemantics(find.bySemanticsLabel('Song merken'));
    expect(data.flagsCollection.isToggled, Tristate.isFalse);
    expect(data.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    tester.semantics.tap(finder);
    await tester.pump();
    data = tester.getSemantics(find.bySemanticsLabel('Song merken'));
    expect(data.flagsCollection.isToggled, Tristate.isTrue);

    tester.semantics.tap(find.semantics.byLabel('Song merken'));
    await tester.pump();
    data = tester.getSemantics(find.bySemanticsLabel('Song merken'));
    expect(data.flagsCollection.isToggled, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('Mausklick schaltet ebenfalls um', (tester) async {
    await pump(tester, initial: false);
    await tester.tap(find.byType(IconAction));
    await tester.pump();
    final widget = tester.widget<IconAction>(find.byType(IconAction));
    expect(widget.toggled, isTrue);
  });
}
