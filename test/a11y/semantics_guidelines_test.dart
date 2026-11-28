// Automated accessibility checks of the core screens in light and dark:
// tap target sizes (Android 48 dp, iOS 44 dp), labelled tap targets and text
// contrast (Flutter's meetsGuideline matchers), text scale 2.0 without
// overflow, and a keyboard focus traversal that follows the reading order.
//
// These run with the normal unit tests in CI (ci.yml) and as the "Semantics"
// job of a11y.yml. What they cannot decide (spoken output of a real screen
// reader) is listed in docs/BARRIEREFREIHEIT.md.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:material_ui/material_ui.dart';

import '../app/app_host.dart';
import '../golden_support.dart';
import 'full_coverage_contrast.dart';

/// Screens reachable through the navigation provider that make up the app.
const List<AppScreen> _screens = <AppScreen>[
  AppScreen.stations,
  AppScreen.player,
  AppScreen.history,
  AppScreen.favorites,
  AppScreen.settings,
  AppScreen.alarm,
  AppScreen.about,
];

/// Screens checked with Flutter's [textContrastGuideline]. On the others
/// (favorites, settings, alarm, about) it reports ratios of 1.1 to 4.0:1 for
/// text whose rendered colour is the token colour at 5.2:1 or better: it
/// picks anti-aliased edge pixels as the text colour (see
/// full_coverage_contrast.dart for the evidence). There the contrast is
/// checked by [FullCoverageContrastGuideline] instead, which also runs on all
/// other screens.
const List<AppScreen> _pixelContrastScreens = <AppScreen>[
  AppScreen.stations,
  AppScreen.player,
  AppScreen.history,
];

AppHost _host(Brightness brightness) => AppHost(
  settings: AppSettings(
    autoplay: false,
    marquee: false,
    themeMode: brightness == Brightness.dark
        ? AppThemeMode.dark
        : AppThemeMode.light,
  ),
);

Future<AppHost> _open(
  WidgetTester tester,
  AppScreen screen,
  Brightness brightness, {
  double width = 390,
  double height = 844,
}) async {
  useSize(tester, width, height);
  final host = _host(brightness);
  await pumpApp(tester, host);
  host.container.read(navigationProvider.notifier).go(screen);
  await settleApp(tester);
  // Let entrance animations finish: the contrast guideline samples pixels, so
  // half-faded text would read as low contrast.
  await tester.pump(const Duration(seconds: 2));
  return host;
}

void main() {
  setUpAll(loadAppFonts);

  for (final brightness in Brightness.values) {
    final mode = brightness.name;

    group('guidelines ($mode)', () {
      for (final screen in _screens) {
        testWidgets('${screen.name}: tap targets and labels', (tester) async {
          ignoreDelegateWarning();
          final handle = tester.ensureSemantics();
          final host = await _open(tester, screen, brightness);

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

          handle.dispose();
          await disposeApp(tester, host);
        });

        testWidgets('${screen.name}: text contrast', (tester) async {
          ignoreDelegateWarning();
          final handle = tester.ensureSemantics();
          final host = await _open(tester, screen, brightness);

          if (_pixelContrastScreens.contains(screen)) {
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          }
          await expectLater(
            tester,
            meetsGuideline(const FullCoverageContrastGuideline()),
          );

          handle.dispose();
          await disposeApp(tester, host);
        });
      }
    });

    group('text scale 2.0 ($mode)', () {
      for (final screen in _screens) {
        testWidgets('${screen.name}: no overflow', (tester) async {
          ignoreDelegateWarning();
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final host = await _open(tester, screen, brightness);

          // A RenderFlex overflow is reported as a FlutterError and surfaces
          // through takeException.
          expect(tester.takeException(), isNull);

          await disposeApp(tester, host);
        });
      }
    });
  }

  _focusReadingOrderTests();
  _textScaleNarrowTests();

  group('focus order', () {
    for (final screen in _screens) {
      testWidgets('${screen.name}: Tab follows the reading order', (
        tester,
      ) async {
        ignoreDelegateWarning();
        final host = await _open(
          tester,
          screen,
          Brightness.dark,
          width: 1000,
          height: 720,
        );

        // Tab through two full cycles: focus must wrap around (no trap) and every
        // stop must be visible, also when re-entering a scrolled list.
        const window = Rect.fromLTWH(0, 0, 1000, 720);
        final stops = <FocusNode>[];
        var period = 0;
        for (var i = 0; i < 200; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          // Scrolling a focused item into view is animated.
          await tester.pump(const Duration(milliseconds: 400));
          final node = FocusManager.instance.primaryFocus;
          if (node == null || node.context == null) continue;
          stops.add(node);
          // Every stop of every pass is on screen (scrolled into view).
          final box = node.context!.findRenderObject();
          if (box is RenderBox && box.hasSize) {
            final rect = box.localToGlobal(Offset.zero) & box.size;
            expect(
              window.overlaps(rect),
              isTrue,
              reason: 'focus moved off screen to $rect (stop ${stops.length})',
            );
          }
          if (period == 0 && stops.length > 1 && identical(stops.first, node)) {
            period = stops.length - 1;
          }
          if (period > 0 && stops.length >= 2 * period) break;
        }
        expect(period, greaterThan(0), reason: 'focus never wrapped around');
        // Navigation first: the first stop is the rail on the left.
        final firstBox = stops.first.context!.findRenderObject()! as RenderBox;
        expect(
          firstBox.localToGlobal(Offset.zero).dx,
          lessThan(110),
          reason: 'the first Tab stop is not the navigation rail',
        );
        await disposeApp(tester, host);
      });
    }
  });
}

/// Reading order of the Tab stops: in a window tall enough that nothing has to
/// scroll, the stops of the content area never jump back up the page, and
/// within one row they run left to right (the text direction).
void _focusReadingOrderTests() {
  group('focus reading order', () {
    for (final screen in _screens) {
      testWidgets('${screen.name}: content stops run top to bottom', (
        tester,
      ) async {
        ignoreDelegateWarning();
        final host = await _open(
          tester,
          screen,
          Brightness.dark,
          width: 1000,
          height: 3000,
        );

        final stops = <Rect>[];
        FocusNode? first;
        for (var i = 0; i < 120; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump(const Duration(milliseconds: 400));
          final node = FocusManager.instance.primaryFocus;
          final box = node?.context?.findRenderObject();
          if (node == null || box is! RenderBox || !box.hasSize) continue;
          // The app-level shell scope covers the whole window; it is the
          // fallback holder between two passes, not a control.
          if (box.size.height >= 3000) continue;
          if (first == null) {
            first = node;
          } else if (identical(first, node)) {
            break; // wrapped around
          }
          stops.add(box.localToGlobal(Offset.zero) & box.size);
        }
        expect(stops, isNotEmpty);

        // Navigation rail stops (left edge) come first, then the content.
        final content = stops.where((r) => r.left >= 110).toList();
        for (var i = 1; i < content.length; i++) {
          final prev = content[i - 1];
          final next = content[i];
          // A control nested in a card shares the card's top edge; controls of
          // different height in one bar share their centre line.
          final sameRow =
              (next.top - prev.top).abs() < 8 ||
              (next.center.dy - prev.center.dy).abs() < 8;
          if (sameRow) {
            expect(
              next.left,
              greaterThanOrEqualTo(prev.left),
              reason: 'stop $i jumps left within a row: $prev -> $next',
            );
          } else {
            expect(
              next.top,
              greaterThan(prev.top),
              reason: 'stop $i jumps up the page: $prev -> $next',
            );
          }
        }
        await disposeApp(tester, host);
      });
    }
  });
}

/// Text scale 2.0 on the narrowest supported phone and with labelled, large
/// enough tap targets (larger text must not shrink or hide controls).
void _textScaleNarrowTests() {
  group('text scale 2.0 on a small phone', () {
    for (final screen in _screens) {
      testWidgets('${screen.name}: no overflow, targets and labels', (
        tester,
      ) async {
        ignoreDelegateWarning();
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final handle = tester.ensureSemantics();
        final host = await _open(
          tester,
          screen,
          Brightness.light,
          width: 320,
          height: 568,
        );

        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        handle.dispose();
        await disposeApp(tester, host);
      });
    }
  });
}
