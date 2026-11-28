import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/app.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/loader/app_loader.dart';
import 'package:linefm_radio/ui/widgets/lifecycle_ticker_mode.dart';
import 'package:material_ui/material_ui.dart';

import '../support/in_memory_prefs_store.dart';
import '../support/service_doubles.dart';

void main() {
  testWidgets('idle app schedules no frames once the loader is gone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    loaderShownThisProcess = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...noopServiceOverrides(),
          prefsProvider.overrideWithValue(InMemoryPrefsStore()),
        ],
        child: const LinefmApp(),
      ),
    );
    await tester.pump();
    await tester.pump(LoaderGate.fadeDuration);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(AppLoader), findsNothing);

    // Nothing changes on screen: no ticker may keep the frame loop alive.
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('LifecycleTickerMode', () {
    Widget host() => const LifecycleTickerMode(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    testWidgets('mutes tickers while the window is hidden', (tester) async {
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await tester.pumpWidget(host());
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.binding.hasScheduledFrame, isTrue);

      // Unfocused but visible desktop window: keeps animating.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.binding.hasScheduledFrame, isTrue);

      // Minimized: no more frames.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);

      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
