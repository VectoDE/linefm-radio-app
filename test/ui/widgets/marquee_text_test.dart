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

  testWidgets('overflowing text animates while in the foreground', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const MarqueeText(_long)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('muted ticker mode leaves the band idle', (tester) async {
    await tester.pumpWidget(_host(const MarqueeText(_long), tickers: false));
    await tester.pump();
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
    await tester.pump(const Duration(milliseconds: 16));

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });
}
