import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/platform/desktop/title_bar.dart';
import 'package:linefm_radio/platform/desktop/window.dart';
import 'package:linefm_radio/platform/desktop/window_caption.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

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

class FakeWindow implements DesktopWindow {
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

const noAutoplay = AppSettings(autoplay: false);

bool focusInBar() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<DesktopTitleBar>() !=
    null;

Widget buildBar(
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

Finder button(CaptionButtonKind kind) =>
    find.byWidgetPredicate((w) => w is CaptionButton && w.kind == kind);

Color buttonBackground(WidgetTester tester, CaptionButtonKind kind) => tester
    .widget<ColoredBox>(
      find.descendant(of: button(kind), matching: find.byType(ColoredBox)),
    )
    .color;

Color glyphColor(WidgetTester tester, CaptionButtonKind kind) =>
    (tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: button(kind),
                    matching: find.byWidgetPredicate(
                      (w) =>
                          w is CustomPaint && w.painter is CaptionGlyphPainter,
                    ),
                  ),
                )
                .painter!
            as CaptionGlyphPainter)
        .color;
