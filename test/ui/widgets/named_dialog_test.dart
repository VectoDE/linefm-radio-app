import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Future<Object?> Function(BuildContext) open) => MaterialApp(
  theme: buildLinefmTheme(Brightness.dark),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => open(context),
          child: const Text('oeffnen'),
        ),
      ),
    ),
  ),
);

/// Semantik-Knoten mit [label] und Rolle [role] (oder null).
SemanticsNode? _find(WidgetTester tester, String label, SemanticsRole role) {
  SemanticsNode? hit;
  bool visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.role == role && data.label == label) {
      hit = node;
      return false;
    }
    node.visitChildren(visit);
    return hit == null;
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return hit;
}

void main() {
  testWidgets('Bottom-Sheet bekommt Rolle dialog mit Namen (R4-D)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        (context) => showModalBottomSheet<void>(
          context: context,
          builder: (_) => const NamedSheet(
            label: 'Sleeptimer',
            child: SizedBox(height: 120, child: Text('Inhalt')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('oeffnen'));
    await tester.pumpAndSettle();

    final node = _find(tester, 'Sleeptimer', SemanticsRole.dialog);
    expect(node, isNotNull);
    expect(node!.getSemanticsData().flagsCollection.namesRoute, isTrue);
    handle.dispose();
  });

  testWidgets('TimePicker mit NamedDialog hat einen Namen (R4-D)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        (context) => showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 7, minute: 0),
          builder: (context, child) => NamedDialog(
            label: MaterialLocalizations.of(context).timePickerDialHelpText,
            child: child!,
          ),
        ),
      ),
    );
    await tester.tap(find.text('oeffnen'));
    await tester.pumpAndSettle();

    final label = MaterialLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    ).timePickerDialHelpText;
    expect(_find(tester, label, SemanticsRole.dialog), isNotNull);
    handle.dispose();
  });

  testWidgets('Dialoge bleiben auf breitem Fenster hoechstens 560 breit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        (context) => showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Titel'),
            content: Text(
              'Ein sehr langer Text, der ohne Begrenzung ueber die ganze '
              'Breite des Fensters laufen wuerde und dann schwer zu lesen '
              'waere, weil die Zeilen viel zu lang werden. Noch mehr Text, '
              'damit die Zeile sicher breiter als 560 Pixel waere.',
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('oeffnen'));
    await tester.pumpAndSettle();

    // Gemessen wird die sichtbare Flaeche (Material), nicht der Dialog-Rahmen,
    // der das ganze Fenster belegt.
    final width = tester
        .getSize(
          find
              .descendant(
                of: find.byType(Dialog),
                matching: find.byType(Material),
              )
              .first,
        )
        .width;
    expect(width, lessThanOrEqualTo(560));
    expect(width, greaterThanOrEqualTo(280));
  });
}
