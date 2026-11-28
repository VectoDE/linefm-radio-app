import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/ui/widgets/marquee_text.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {bool tickers = true}) => MaterialApp(
  home: Scaffold(
    body: TickerMode(
      enabled: tickers,
      child: Center(child: SizedBox(width: 120, child: child)),
    ),
  ),
);

const _long = 'A very long title that never fits into this narrow box at all';

void main() {
  testWidgets('short text schedules no frames', (tester) async {
    await tester.pumpWidget(_host(const MarqueeText('Hi')));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  double bandOffset(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(MarqueeText, skipOffstage: false),
        matching: find.byType(Transform, skipOffstage: false),
      ),
    );
    return transform.transform.getTranslation().x;
  }

  testWidgets('overflowing text moves while in the foreground', (tester) async {
    await tester.pumpWidget(_host(const MarqueeText(_long)));
    final start = bandOffset(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(bandOffset(tester), lessThan(start));
  });

  testWidgets('band moves in whole pixels, not on every vsync', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(const MarqueeText(_long)));
    // Shorter than one pixel step of an 18 s loop: nothing to draw.
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 1));
    final x = bandOffset(tester);
    expect(x, lessThan(0));
    expect(x, x.roundToDouble());
  });

  testWidgets('muted ticker mode leaves the band idle', (tester) async {
    await tester.pumpWidget(_host(const MarqueeText(_long), tickers: false));
    final start = bandOffset(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(bandOffset(tester), start);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('band stops in the background and resumes in the foreground', (
    tester,
  ) async {
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await tester.pumpWidget(_host(const MarqueeText(_long)));
    await tester.pump(const Duration(milliseconds: 500));

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    final paused = bandOffset(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(bandOffset(tester), paused);
    expect(tester.binding.hasScheduledFrame, isFalse);

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(bandOffset(tester), lessThan(paused));
  });

  testWidgets('band scrolled out of its viewport holds still', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: controller,
            // Keep the band alive in the cache area when scrolled away.
            scrollCacheExtent: const ScrollCacheExtent.pixels(5000),
            children: const <Widget>[
              SizedBox(width: 120, child: MarqueeText(_long)),
              SizedBox(height: 3000),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    controller.jumpTo(2000);
    await tester.pump();
    await tester.pump();
    final away = bandOffset(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(bandOffset(tester), away);
    expect(tester.binding.hasScheduledFrame, isFalse);

    controller.jumpTo(0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(bandOffset(tester), lessThan(away));
  });
}
