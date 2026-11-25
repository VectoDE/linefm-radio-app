import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/platform/desktop/window_reveal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowRevealChannel, (call) async {
          calls.add(call.method);
          return null;
        });
  });

  group('revealWindowWhenPresented', () {
    test('reveals only once the loader is presented', () async {
      final presented = Completer<void>();
      final done = revealWindowWhenPresented(
        isWindows: true,
        presented: () => presented.future,
      );
      expect(pendingWindowReveal, isNotNull);
      await Future<void>.delayed(Duration.zero);
      expect(calls, isEmpty);
      presented.complete();
      await done;
      expect(calls, <String>['reveal']);
      expect(pendingWindowReveal, isNull);
    });

    test('does nothing outside Windows', () async {
      await revealWindowWhenPresented(isWindows: false);
      expect(calls, isEmpty);
      expect(pendingWindowReveal, isNull);
    });

    test('defaults to the current platform (not Windows in tests)', () async {
      await revealWindowWhenPresented();
      expect(calls, isEmpty);
    });

    test('a failing channel still releases the pending reveal', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowRevealChannel, (call) async {
            throw PlatformException(code: 'gone');
          });
      final pending = <Future<void>?>[];
      await revealWindowWhenPresented(
        isWindows: true,
        presented: () async => pending.add(pendingWindowReveal),
      );
      expect(pending.single, isNotNull);
      await pending.single; // completes despite the error
      expect(pendingWindowReveal, isNull);
    });
  });

  test(
    'loaderPresented waits for the first frame, then stable frames',
    () async {
      final first = Completer<void>();
      var frames = 0;
      var finished = false;
      final done = loaderPresented(
        firstFrame: first.future,
        nextFrame: () async => frames++,
        size: () => const Size(800, 600),
      ).then((_) => finished = true);
      await Future<void>.delayed(Duration.zero);
      expect(frames, 0);
      expect(finished, isFalse);
      first.complete();
      await done;
      expect(frames, revealAfterRasterizedFrames);
    },
  );

  testWidgets('loaderPresented uses the binding frames by default', (
    tester,
  ) async {
    var finished = false;
    unawaited(
      loaderPresented(firstFrame: Future<void>.value()).then((_) {
        finished = true;
      }),
    );
    for (var i = 0; i < 10 && !finished; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(finished, isTrue);
  });

  group('waitForStableFrames', () {
    test('needs the configured number of frames at one size', () async {
      final waited = await waitForStableFrames(
        nextFrame: () async {},
        size: () => const Size(1280, 720),
      );
      expect(waited, revealAfterRasterizedFrames);
    });

    test('a resize (maximised restore) restarts the count', () async {
      final sizes = <Size>[
        const Size(1280, 720), // before the first wait
        const Size(1936, 1048), // resized after the first frame
        const Size(1936, 1048),
        const Size(1936, 1048),
      ];
      var i = 0;
      final waited = await waitForStableFrames(
        nextFrame: () async => i++,
        size: () => sizes[i.clamp(0, sizes.length - 1)],
      );
      // 1 frame at the new size resets, then 2 stable frames.
      expect(waited, 3);
    });

    test('gives up after the cap', () async {
      var clock = DateTime(2026);
      var frame = 0;
      final waited = await waitForStableFrames(
        nextFrame: () async {
          frame++;
          clock = clock.add(const Duration(milliseconds: 500));
        },
        // Size keeps changing, so it never becomes stable.
        size: () => Size(1000.0 + frame, 700),
        now: () => clock,
      );
      expect(waited, 3);
    });
  });
}
