import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/platform/desktop/title_bar.dart';
import 'package:linefm_radio/platform/desktop/window_caption.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

import 'title_bar_helpers.dart';

void main() {
  group('DesktopTitleBar Windows/Linux', () {
    testWidgets('Logo, Name, drei Schaltflaechen in Systemreihenfolge', (
      tester,
    ) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(buildBar(caption));

      final bar = find.byType(DesktopTitleBar);
      expect(tester.getSize(bar).height, TitleBarMetrics.height);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('LINEFM RADIO', findRichText: true), findsOneWidget);

      final xs = <double>[
        for (final kind in <CaptionButtonKind>[
          CaptionButtonKind.minimize,
          CaptionButtonKind.maximize,
          CaptionButtonKind.close,
        ])
          tester.getTopLeft(button(kind)).dx,
      ];
      expect(xs, orderedEquals(List<double>.of(xs)..sort()));
      expect(
        tester.getSize(button(CaptionButtonKind.close)),
        const Size(46, 40),
      );
      // Schliessen schliesst buendig rechts ab.
      expect(
        tester.getTopRight(button(CaptionButtonKind.close)).dx,
        tester.getTopRight(bar).dx,
      );
      // Snap-Layouts: nur der Maximieren-Knopf liegt in der Systemflaeche.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('maxArea')),
          matching: button(CaptionButtonKind.maximize),
        ),
        findsOneWidget,
      );
      // Logo und Name ziehen das Fenster, die Knoepfe nicht.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('drag')),
          matching: find.byType(CaptionButton),
        ),
        findsNothing,
      );
    });

    testWidgets('Klicks rufen die Fenster-Aktionen', (tester) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(buildBar(caption));

      await tester.tap(button(CaptionButtonKind.minimize));
      await tester.tap(button(CaptionButtonKind.maximize));
      await tester.tap(button(CaptionButtonKind.close));
      expect(caption.calls, <String>['minimize', 'toggleMaximize', 'close']);
    });

    testWidgets('Maximiert: Wiederherstellen statt Maximieren', (tester) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(buildBar(caption));
      expect(find.bySemanticsLabel('Maximieren'), findsOneWidget);

      caption.state.value = const WindowFrameState(maximized: true);
      await tester.pump();
      expect(button(CaptionButtonKind.maximize), findsNothing);
      expect(button(CaptionButtonKind.restore), findsOneWidget);
      expect(find.bySemanticsLabel('Wiederherstellen'), findsOneWidget);
      await tester.tap(button(CaptionButtonKind.restore));
      expect(caption.calls, <String>['toggleMaximize']);
    });

    testWidgets('Namen fuer Screenreader folgen der App-Sprache', (
      tester,
    ) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(buildBar(caption));
      for (final label in <String>['Minimieren', 'Maximieren', 'Schließen']) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }

      await tester.pumpWidget(buildBar(caption, locale: const Locale('en')));
      await tester.pump();
      for (final label in <String>['Minimize', 'Maximize', 'Close']) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      expect(find.bySemanticsLabel('Minimieren'), findsNothing);
    });

    testWidgets('Hover, gedrueckt und rotes Schliessen', (tester) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(buildBar(caption));
      const c = LinefmColors.dark;

      expect(
        buttonBackground(tester, CaptionButtonKind.minimize),
        const Color(0x00000000),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(tester.getCenter(button(CaptionButtonKind.minimize)));
      await tester.pump();
      expect(
        buttonBackground(tester, CaptionButtonKind.minimize),
        c.text.withValues(alpha: 0.08),
      );

      await mouse.down(tester.getCenter(button(CaptionButtonKind.minimize)));
      await tester.pump();
      expect(
        buttonBackground(tester, CaptionButtonKind.minimize),
        c.text.withValues(alpha: 0.12),
      );
      await mouse.up();
      await tester.pump();

      await mouse.moveTo(tester.getCenter(button(CaptionButtonKind.close)));
      await tester.pump();
      expect(
        buttonBackground(tester, CaptionButtonKind.close),
        TitleBarMetrics.closeHover,
      );
      expect(
        glyphColor(tester, CaptionButtonKind.close),
        TitleBarMetrics.onClose,
      );
      await mouse.down(tester.getCenter(button(CaptionButtonKind.close)));
      await tester.pump();
      expect(
        buttonBackground(tester, CaptionButtonKind.close),
        TitleBarMetrics.closePressed,
      );
      await mouse.up();
      await tester.pump();
      expect(caption.calls, <String>['minimize', 'close']);
    });

    testWidgets('Inaktives Fenster: gedaempfte Symbole', (tester) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(buildBar(caption, brightness: Brightness.light));
      const c = LinefmColors.light;
      expect(glyphColor(tester, CaptionButtonKind.minimize), c.text);

      caption.state.value = const WindowFrameState(active: false);
      await tester.pump();
      for (final kind in <CaptionButtonKind>[
        CaptionButtonKind.minimize,
        CaptionButtonKind.maximize,
        CaptionButtonKind.close,
      ]) {
        expect(glyphColor(tester, kind), c.muted);
      }
    });

    testWidgets('Tastatur: Fokus und Enter loesen aus', (tester) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(buildBar(caption));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(caption.calls, <String>['minimize']);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(caption.calls, <String>['minimize', 'close']);
    });

    testWidgets('Vollbild: keine Leiste', (tester) async {
      final caption = FakeCaption(
        CaptionStyle.buttons,
        const WindowFrameState(fullScreen: true),
      );
      await tester.pumpWidget(buildBar(caption));
      expect(tester.getSize(find.byType(DesktopTitleBar)).height, 0);
      expect(find.byType(CaptionButton), findsNothing);
    });
  });
}
