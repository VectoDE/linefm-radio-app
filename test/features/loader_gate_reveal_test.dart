import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/features/loader/app_loader.dart';
import 'package:linefm_radio/platform/desktop/window_reveal.dart';
import 'package:material_ui/material_ui.dart';

import 'feature_host.dart';

void main() {
  tearDown(() => pendingWindowReveal = null);

  testWidgets('minimum display time starts only when the window is revealed', (
    tester,
  ) async {
    loaderShownThisProcess = false;
    final revealed = Completer<void>();
    pendingWindowReveal = revealed.future;

    await tester.pumpWidget(
      FeatureHost().app(
        const LoaderGate(
          minDuration: Duration(milliseconds: 300),
          child: Text('content'),
        ),
        scaffold: false,
      ),
    );
    // Window still cloaked: however long it takes, the loader stays.
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(AppLoader), findsOneWidget);

    revealed.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 299));
    expect(find.byType(AppLoader), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(LoaderGate.fadeDuration);
    await tester.pump();
    expect(find.byType(AppLoader), findsNothing);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('without a pending reveal the timer starts right away', (
    tester,
  ) async {
    loaderShownThisProcess = false;
    await tester.pumpWidget(
      FeatureHost().app(
        const LoaderGate(
          minDuration: Duration(milliseconds: 300),
          child: Text('content'),
        ),
        scaffold: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(LoaderGate.fadeDuration);
    await tester.pump();
    expect(find.byType(AppLoader), findsNothing);
  });

  testWidgets('disposed before the reveal: no timer, no error', (tester) async {
    loaderShownThisProcess = false;
    final revealed = Completer<void>();
    pendingWindowReveal = revealed.future;
    await tester.pumpWidget(
      FeatureHost().app(
        const LoaderGate(child: Text('content')),
        scaffold: false,
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    revealed.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
