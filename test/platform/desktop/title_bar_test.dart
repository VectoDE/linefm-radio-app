import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/platform/desktop/desktop_controller.dart';
import 'package:linefm_radio/platform/desktop/mini_window.dart';
import 'package:linefm_radio/platform/desktop/title_bar.dart';
import 'package:linefm_radio/platform/desktop/window.dart';
import 'package:linefm_radio/platform/desktop/window_caption.dart';
import 'package:linefm_radio/ui/theme/contrast.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_host.dart';

/// Fenster-Aktionen der Leiste ohne window_manager.
class FakeCaption implements WindowCaptionControls {
  FakeCaption(this.style, [WindowFrameState state = const WindowFrameState()])
    : state = ValueNotifier<WindowFrameState>(state);

  @override
  final CaptionStyle style;

  final ValueNotifier<WindowFrameState> state;
  final List<String> calls = <String>[];
  final List<bool> resizeEnabled = <bool>[];

  @override
  ValueListenable<WindowFrameState> get frameState => state;

  @override
  Future<void> minimize() async => calls.add('minimize');

  @override
  Future<void> toggleMaximize() async => calls.add('toggleMaximize');

  @override
  Future<void> close() async => calls.add('close');

  @override
  Widget dragArea(Widget child) =>
      KeyedSubtree(key: const ValueKey<String>('drag'), child: child);

  @override
  Widget maximizeButtonArea(Widget child) =>
      KeyedSubtree(key: const ValueKey<String>('maxArea'), child: child);

  @override
  Widget resizeArea(Widget child, {required bool enabled}) {
    resizeEnabled.add(enabled);
    return child;
  }
}

class _FakeWindow implements DesktopWindow {
  final List<String> calls = <String>[];

  @override
  set trayAvailable(bool value) {}

  @override
  Future<void> show() async => calls.add('show');

  @override
  Future<void> hide() async => calls.add('hide');

  @override
  Future<void> setAlwaysOnTop({required bool value}) async {}

  @override
  Future<void> enterMini({required bool alwaysOnTop}) async =>
      calls.add('enterMini');

  @override
  Future<void> exitMini({required bool alwaysOnTop}) async =>
      calls.add('exitMini');

  @override
  Future<void> setCloseToTray({required bool value}) async {}

  @override
  Future<void> quit() async => calls.add('quit');
}

const _noAutoplay = AppSettings(autoplay: false);

bool _focusInBar() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<DesktopTitleBar>() !=
    null;

Widget _bar(
  FakeCaption caption, {
  Brightness brightness = Brightness.dark,
  Locale locale = const Locale('de'),
}) => MaterialApp(
  theme: buildLinefmTheme(brightness),
  locale: locale,
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: ValueListenableBuilder<WindowFrameState>(
        valueListenable: caption.state,
        builder: (context, state, _) =>
            DesktopTitleBar(controls: caption, state: state),
      ),
    ),
  ),
);

Finder _button(CaptionButtonKind kind) =>
    find.byWidgetPredicate((w) => w is CaptionButton && w.kind == kind);

Color _buttonBackground(WidgetTester tester, CaptionButtonKind kind) => tester
    .widget<ColoredBox>(
      find.descendant(of: _button(kind), matching: find.byType(ColoredBox)),
    )
    .color;

Color _glyphColor(WidgetTester tester, CaptionButtonKind kind) =>
    (tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: _button(kind),
                    matching: find.byWidgetPredicate(
                      (w) =>
                          w is CustomPaint && w.painter is CaptionGlyphPainter,
                    ),
                  ),
                )
                .painter!
            as CaptionGlyphPainter)
        .color;

void main() {
  group('DesktopTitleBar Windows/Linux', () {
    testWidgets('Logo, Name, drei Schaltflaechen in Systemreihenfolge', (
      tester,
    ) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(_bar(caption));

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
          tester.getTopLeft(_button(kind)).dx,
      ];
      expect(xs, orderedEquals(List<double>.of(xs)..sort()));
      expect(
        tester.getSize(_button(CaptionButtonKind.close)),
        const Size(46, 40),
      );
      // Schliessen schliesst buendig rechts ab.
      expect(
        tester.getTopRight(_button(CaptionButtonKind.close)).dx,
        tester.getTopRight(bar).dx,
      );
      // Snap-Layouts: nur der Maximieren-Knopf liegt in der Systemflaeche.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('maxArea')),
          matching: _button(CaptionButtonKind.maximize),
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
      await tester.pumpWidget(_bar(caption));

      await tester.tap(_button(CaptionButtonKind.minimize));
      await tester.tap(_button(CaptionButtonKind.maximize));
      await tester.tap(_button(CaptionButtonKind.close));
      expect(caption.calls, <String>['minimize', 'toggleMaximize', 'close']);
    });

    testWidgets('Maximiert: Wiederherstellen statt Maximieren', (tester) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(_bar(caption));
      expect(find.bySemanticsLabel('Maximieren'), findsOneWidget);

      caption.state.value = const WindowFrameState(maximized: true);
      await tester.pump();
      expect(_button(CaptionButtonKind.maximize), findsNothing);
      expect(_button(CaptionButtonKind.restore), findsOneWidget);
      expect(find.bySemanticsLabel('Wiederherstellen'), findsOneWidget);
      await tester.tap(_button(CaptionButtonKind.restore));
      expect(caption.calls, <String>['toggleMaximize']);
    });

    testWidgets('Namen fuer Screenreader folgen der App-Sprache', (
      tester,
    ) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(_bar(caption));
      for (final label in <String>['Minimieren', 'Maximieren', 'Schließen']) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }

      await tester.pumpWidget(_bar(caption, locale: const Locale('en')));
      await tester.pump();
      for (final label in <String>['Minimize', 'Maximize', 'Close']) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      expect(find.bySemanticsLabel('Minimieren'), findsNothing);
    });

    testWidgets('Hover, gedrueckt und rotes Schliessen', (tester) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(_bar(caption));
      const c = LinefmColors.dark;

      expect(
        _buttonBackground(tester, CaptionButtonKind.minimize),
        const Color(0x00000000),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(tester.getCenter(_button(CaptionButtonKind.minimize)));
      await tester.pump();
      expect(
        _buttonBackground(tester, CaptionButtonKind.minimize),
        c.text.withValues(alpha: 0.08),
      );

      await mouse.down(tester.getCenter(_button(CaptionButtonKind.minimize)));
      await tester.pump();
      expect(
        _buttonBackground(tester, CaptionButtonKind.minimize),
        c.text.withValues(alpha: 0.12),
      );
      await mouse.up();
      await tester.pump();

      await mouse.moveTo(tester.getCenter(_button(CaptionButtonKind.close)));
      await tester.pump();
      expect(
        _buttonBackground(tester, CaptionButtonKind.close),
        TitleBarMetrics.closeHover,
      );
      expect(
        _glyphColor(tester, CaptionButtonKind.close),
        TitleBarMetrics.onClose,
      );
      await mouse.down(tester.getCenter(_button(CaptionButtonKind.close)));
      await tester.pump();
      expect(
        _buttonBackground(tester, CaptionButtonKind.close),
        TitleBarMetrics.closePressed,
      );
      await mouse.up();
      await tester.pump();
      expect(caption.calls, <String>['minimize', 'close']);
    });

    testWidgets('Inaktives Fenster: gedaempfte Symbole', (tester) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(_bar(caption, brightness: Brightness.light));
      const c = LinefmColors.light;
      expect(_glyphColor(tester, CaptionButtonKind.minimize), c.text);

      caption.state.value = const WindowFrameState(active: false);
      await tester.pump();
      for (final kind in <CaptionButtonKind>[
        CaptionButtonKind.minimize,
        CaptionButtonKind.maximize,
        CaptionButtonKind.close,
      ]) {
        expect(_glyphColor(tester, kind), c.muted);
      }
    });

    testWidgets('Tastatur: Fokus und Enter loesen aus', (tester) async {
      final caption = FakeCaption(CaptionStyle.buttons);
      await tester.pumpWidget(_bar(caption));

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
      await tester.pumpWidget(_bar(caption));
      expect(tester.getSize(find.byType(DesktopTitleBar)).height, 0);
      expect(find.byType(CaptionButton), findsNothing);
    });
  });

  group('DesktopTitleBar macOS', () {
    testWidgets('keine eigenen Knoepfe, Platz fuer die Ampeln', (tester) async {
      final caption = FakeCaption(CaptionStyle.macos);
      await tester.pumpWidget(_bar(caption));

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
    late _FakeWindow window;
    final desktop = DesktopController.instance;

    setUp(() {
      caption = FakeCaption(CaptionStyle.buttons);
      window = _FakeWindow();
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
      final host = AppHost(settings: _noAutoplay);
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
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);

      // Wie bei nativen Titelleisten: Tab laeuft durch die App, ohne in die
      // Leiste zu springen (Fenster-Aktionen per Tastatur: Systemmenue).
      for (var i = 0; i < 60; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, isNotNull);
        expect(_focusInBar(), isFalse, reason: 'Schritt $i');
      }
      await disposeApp(tester, host);
    });

    testWidgets('Ohne eigene Leiste bleibt alles wie bisher', (tester) async {
      desktop.caption = NoopWindowCaptionControls();
      useSize(tester, 1280, 720);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);
      expect(find.byType(DesktopTitleBar), findsNothing);
      await disposeApp(tester, host);
    });
  });
}
