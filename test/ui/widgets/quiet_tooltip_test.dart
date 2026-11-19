import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/ui/widgets/quiet_tooltip.dart';
import 'package:material_ui/material_ui.dart';

Widget _app({String message = 'Einstellungen'}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: QuietTooltip(
        message: message,
        child: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings, semanticLabel: 'Einstellungen'),
        ),
      ),
    ),
  ),
);

int _nodeCount(WidgetTester tester) {
  var count = 0;
  bool visit(SemanticsNode node) {
    count++;
    node.visitChildren(visit);
    return true;
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return count;
}

void main() {
  testWidgets('Hover zeigt die Blase, ohne neuen Semantik-Knoten', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    expect(find.text('Einstellungen'), findsNothing);
    final before = _nodeCount(tester);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(IconButton)));
    await tester.pump(const Duration(seconds: 1));

    // Blase sichtbar ...
    expect(find.text('Einstellungen'), findsOneWidget);
    // Ohne Material im Overlay keine gelbe Warn-Unterstreichung.
    expect(
      DefaultTextStyle.of(tester.element(find.text('Einstellungen')))
          .style
          .decoration,
      TextDecoration.none,
    );
    // ... aber kein Knoten dazu (kein OverlayPortal, kein aria-owns im Web).
    expect(_nodeCount(tester), before);
    expect(find.bySemanticsLabel('Einstellungen'), findsOneWidget);

    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Einstellungen'), findsNothing);
    handle.dispose();
  });

  testWidgets('Langdruck zeigt die Blase kurz, Tippen bleibt Tippen', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: QuietTooltip(
              message: 'Löschen',
              child: IconButton(
                onPressed: () => taps++,
                icon: const Icon(Icons.delete, semanticLabel: 'Löschen'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(taps, 1);
    expect(find.text('Löschen'), findsNothing);

    await tester.longPress(find.byType(IconButton));
    await tester.pump();
    expect(find.text('Löschen'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Löschen'), findsNothing);
  });

  testWidgets('Leere Meldung: keine Blase', (tester) async {
    await tester.pumpWidget(_app(message: ''));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(IconButton)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Text), findsNothing);
  });

  group('WCAG 1.4.13', () {
    Future<TestGesture> hover(WidgetTester tester) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(IconButton)));
      await tester.pump(const Duration(seconds: 1));
      return mouse;
    }

    testWidgets('Escape schliesst die Blase', (tester) async {
      await tester.pumpWidget(_app());
      await hover(tester);
      expect(find.text('Einstellungen'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Einstellungen'), findsNothing);
    });

    testWidgets('Blase bleibt, solange der Zeiger auf ihr liegt', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      final mouse = await hover(tester);
      final bubble = tester.getCenter(find.text('Einstellungen'));
      await mouse.moveTo(bubble);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Einstellungen'), findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Einstellungen'), findsNothing);
    });

    testWidgets('Tastaturfokus zeigt die Blase, ohne Semantik-Knoten', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app());
      final before = _nodeCount(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.highlightMode,
        FocusHighlightMode.traditional,
      );
      expect(find.text('Einstellungen'), findsOneWidget);
      expect(_nodeCount(tester), before);
      expect(find.bySemanticsLabel('Einstellungen'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Einstellungen'), findsNothing);
      // Escape bewegt den Fokus nicht.
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<IconButton>(),
        isNotNull,
      );
      handle.dispose();
    });
  });

  group('R4-G', () {
    testWidgets('Meldungswechsel leer/voll behaelt den Fokus des Kindes', (
      tester,
    ) async {
      final node = FocusNode(debugLabel: 'kind');
      addTearDown(node.dispose);
      Widget build(String message) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: QuietTooltip(
              message: message,
              child: IconButton(
                focusNode: node,
                onPressed: () {},
                icon: const Icon(Icons.cast, semanticLabel: 'Cast'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(build(''));
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
      final before = tester.element(find.byType(IconButton));
      await tester.pumpWidget(build('Auf Geraet uebertragen'));
      expect(node.hasFocus, isTrue);
      // Gleiches Element: das Kind wurde nicht neu eingehaengt.
      expect(tester.element(find.byType(IconButton)), same(before));
      expect(find.byType(Focus), findsWidgets);
    });

    testWidgets('Escape ohne sichtbare Blase wird nicht abgefangen', (
      tester,
    ) async {
      var seen = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              autofocus: true,
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  seen++;
                }
                return KeyEventResult.ignored;
              },
              child: Center(
                child: QuietTooltip(
                  message: 'Einstellungen',
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(seen, 1);
    });

    testWidgets('Blase blendet ein, bei reduzierter Bewegung sofort', (
      tester,
    ) async {
      Future<double> opacityAfterHover({required bool reduce}) async {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: _app(),
          ),
        );
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(find.byType(IconButton)));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 1));
        final opacities = tester
            .widgetList<Opacity>(
              find.ancestor(
                of: find.text('Einstellungen'),
                matching: find.byType(Opacity),
              ),
            )
            .map((o) => o.opacity)
            .toList();
        await mouse.moveTo(Offset.zero);
        await tester.pump(const Duration(seconds: 1));
        await mouse.removePointer();
        return opacities.isEmpty ? 1 : opacities.first;
      }

      expect(fadeDuration.inMilliseconds, lessThanOrEqualTo(150));
      expect(await opacityAfterHover(reduce: true), 1);
      expect(await opacityAfterHover(reduce: false), lessThan(1));
    });
  });
}
