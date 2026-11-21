@Tags(<String>['golden'])
library;

// Bildvergleich der eigenen Fenster-Titelleiste in Dark und Hell (Issue #87).
// Referenzbilder entstehen auf dem CI-Runner, siehe test/golden_support.dart.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/platform/desktop/title_bar.dart';
import 'package:linefm_radio/platform/desktop/window_caption.dart';
import 'package:material_ui/material_ui.dart';

import '../../golden_support.dart';

class _Caption implements WindowCaptionControls {
  _Caption(this.style);

  @override
  final CaptionStyle style;

  @override
  ValueListenable<WindowFrameState> get frameState =>
      ValueNotifier<WindowFrameState>(const WindowFrameState());

  @override
  Future<void> minimize() async {}

  @override
  Future<void> toggleMaximize() async {}

  @override
  Future<void> close() async {}

  @override
  Widget dragArea(Widget child) => child;

  @override
  Widget maximizeButtonArea(Widget child) => child;

  @override
  Widget resizeArea(Widget child, {required bool enabled}) => child;
}

void main() {
  setUpAll(prepareGoldens);

  for (final brightness in Brightness.values) {
    final mode = variant(brightness);

    group('Golden $mode', () {
      for (final (name, style, state)
          in <(String, CaptionStyle, WindowFrameState)>[
            ('title_bar', CaptionStyle.buttons, const WindowFrameState()),
            (
              'title_bar_maximized_inactive',
              CaptionStyle.buttons,
              const WindowFrameState(maximized: true, active: false),
            ),
            ('title_bar_macos', CaptionStyle.macos, const WindowFrameState()),
          ]) {
        testWidgets('Titelleiste $name', (tester) async {
          ignoreDelegateWarning();
          useGoldenSize(tester, const Size(640, 56));
          await tester.pumpWidget(
            goldenApp(
              brightness: brightness,
              child: Align(
                alignment: Alignment.topCenter,
                child: DesktopTitleBar(controls: _Caption(style), state: state),
              ),
            ),
          );
          await settleImages(tester);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/${name}_$mode.png'),
          );
        });
      }
    });
  }
}
