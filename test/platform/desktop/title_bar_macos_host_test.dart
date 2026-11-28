import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/platform/desktop/desktop_controller.dart';
import 'package:linefm_radio/platform/desktop/mini_window.dart';
import 'package:linefm_radio/platform/desktop/title_bar.dart';
import 'package:linefm_radio/platform/desktop/window.dart';
import 'package:linefm_radio/platform/desktop/window_caption.dart';
import 'package:linefm_radio/ui/theme/contrast.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_host.dart';
import 'title_bar_helpers.dart';

void main() {
  group('DesktopTitleBar macOS', () {
    testWidgets('keine eigenen Knoepfe, Platz fuer die Ampeln', (tester) async {
      final caption = FakeCaption(CaptionStyle.macos);
      await tester.pumpWidget(buildBar(caption));

      expect(
        tester.getSize(find.byType(DesktopTitleBar)).height,
        TitleBarMetrics.heightMacos,
      );
      expect(find.byType(CaptionButton), findsNothing);
      expect(
        tester.getTopLeft(find.byType(Image)).dx,
        greaterThanOrEqualTo(TitleBarMetrics.macosTrafficLightInset),
      );
      expect(find.byKey(const ValueKey<String>('drag')), findsOneWidget);
    });
  });

  group('Kontrast (WCAG AA)', () {
    test('Name, gedaempfter Name und Symbole in Dunkel und Hell', () {
      for (final c in <LinefmColors>[LinefmColors.dark, LinefmColors.light]) {
        expect(Contrast.ratio(c.text, c.background), greaterThan(7));
        expect(
          Contrast.ratio(c.muted, c.background),
          greaterThanOrEqualTo(Contrast.aaText),
        );
        // Symbol auf Hover- und Druckflaeche.
        for (final alpha in <double>[0.08, 0.12]) {
          final hover = Color.alphaBlend(
            c.text.withValues(alpha: alpha),
            c.background,
          );
          expect(
            Contrast.ratio(c.text, hover),
            greaterThanOrEqualTo(Contrast.aaText),
          );
          expect(
            Contrast.ratio(c.muted, hover),
            greaterThanOrEqualTo(Contrast.aaLarge),
          );
        }
        final pressed = Color.alphaBlend(
          TitleBarMetrics.closePressed,
          c.background,
        );
        expect(
          Contrast.ratio(TitleBarMetrics.onClose, pressed),
          greaterThanOrEqualTo(Contrast.aaText),
        );
      }
      expect(
        Contrast.ratio(TitleBarMetrics.onClose, TitleBarMetrics.closeHover),
        greaterThanOrEqualTo(Contrast.aaText),
      );
    });
  });

  group('DesktopHost mit eigener Leiste', () {
    late FakeCaption caption;
    late FakeWindow window;
    final desktop = DesktopController.instance;

    setUp(() {
      caption = FakeCaption(CaptionStyle.buttons);
      window = FakeWindow();
      desktop
        ..caption = caption
        ..window = window
        ..active = true;
    });

    tearDown(() {
      desktop
        ..caption = NoopWindowCaptionControls()
        ..window = const NoopDesktopWindow()
        ..active = false
        ..miniMode.value = false
        ..alwaysOnTop.value = false;
    });

    testWidgets('Leiste ueber der App, Inhalt darunter, Mini ohne Leiste', (
      tester,
    ) async {
      useSize(tester, 1280, 720);
      final host = AppHost(settings: noAutoplay);
      await pumpApp(tester, host);

      expect(find.byType(DesktopTitleBar), findsOneWidget);
      expect(tester.getTopLeft(find.byType(DesktopTitleBar)).dy, 0);
      // Der App-Header beginnt unter der Leiste, nichts liegt darunter.
      final header = find.bySemanticsLabel('LINEFM');
      expect(
        tester.getTopLeft(header.first).dy,
        greaterThanOrEqualTo(TitleBarMetrics.height),
      );
      expect(caption.resizeEnabled.last, isTrue);

      // Maximiert: keine Griffe, Baum der App bleibt.
      caption.state.value = const WindowFrameState(maximized: true);
      await tester.pump();
      expect(caption.resizeEnabled.last, isFalse);
      expect(find.byType(CaptionButton), findsNWidgets(3));

      // Mini-Fenster: nur das Mini-Fenster, keine zweite Leiste.
      await desktop.enterMini();
      await settleApp(tester);
      expect(window.calls, contains('enterMini'));
      expect(find.byType(MiniPlayerWindow), findsOneWidget);
      expect(find.byType(DesktopTitleBar), findsNothing);
      expect(find.byType(CaptionButton), findsNothing);

      await desktop.exitMini();
      await settleApp(tester);
      expect(find.byType(DesktopTitleBar), findsOneWidget);
      expect(find.byType(MiniPlayerWindow), findsNothing);
      await disposeApp(tester, host);
    });

    testWidgets('Tab bleibt im Inhalt, die Leiste steht nie davor', (
      tester,
    ) async {
      useSize(tester, 1280, 720);
      final host = AppHost(settings: noAutoplay);
      await pumpApp(tester, host);

      // Wie bei nativen Titelleisten: Tab laeuft durch die App, ohne in die
      // Leiste zu springen (Fenster-Aktionen per Tastatur: Systemmenue).
      for (var i = 0; i < 60; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, isNotNull);
        expect(focusInBar(), isFalse, reason: 'Schritt $i');
      }
      await disposeApp(tester, host);
    });

    testWidgets('Ohne eigene Leiste bleibt alles wie bisher', (tester) async {
      desktop.caption = NoopWindowCaptionControls();
      useSize(tester, 1280, 720);
      final host = AppHost(settings: noAutoplay);
      await pumpApp(tester, host);
      expect(find.byType(DesktopTitleBar), findsNothing);
      await disposeApp(tester, host);
    });
  });
}
