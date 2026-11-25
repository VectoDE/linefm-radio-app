import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Channel to the Windows runner (windows/runner/flutter_window.cpp).
const MethodChannel windowRevealChannel = MethodChannel(
  'de.linefm.app/window_reveal',
);

/// Set while the Windows window is still cloaked; completes once it is
/// revealed. The loader starts its minimum display time only then, so it is
/// not already fading when the window appears.
Future<void>? pendingWindowReveal;

/// Tells the Windows runner that the loader is on screen, so it can lift the
/// cloak of its window. The runner creates the window cloaked because the
/// first-frame callback fires before the Flutter surface is presented; waiting
/// for the first rasterised frame plus one more frame makes sure the loader is
/// what appears. Without this signal the runner reveals after a timeout.
Future<void> revealWindowWhenPresented({
  bool? isWindows,
  Future<void> Function()? presented,
  MethodChannel channel = windowRevealChannel,
}) async {
  final windows =
      isWindows ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows);
  if (!windows) return;
  final shown = Completer<void>();
  pendingWindowReveal = shown.future;
  try {
    await (presented ?? loaderPresented)();
    await channel.invokeMethod<void>('reveal');
  } on Object catch (e) {
    debugPrint('Window reveal signal failed: $e');
  } finally {
    shown.complete();
    pendingWindowReveal = null;
  }
}

/// Frames that must be rasterised before the window is revealed. Measured on
/// Windows (release, Impeller/ANGLE): the swap chain reaches the screen one
/// to several frames after the first-frame callback; revealing after the
/// first one showed the bare window background for 150 to 220 ms.
const int revealAfterRasterizedFrames = 2;

/// Upper bound for [waitForStableFrames]; the runner's own fallback timer
/// (2 s) is longer.
const Duration revealWaitCap = Duration(milliseconds: 1500);

/// Default wait of [revealWindowWhenPresented]: first rasterised frame,
/// then [waitForStableFrames] on the implicit view. The parameters replace
/// the binding in tests.
@visibleForTesting
Future<void> loaderPresented({
  Future<void>? firstFrame,
  Future<void> Function()? nextFrame,
  Size? Function()? size,
}) async {
  final binding = WidgetsBinding.instance;
  await (firstFrame ?? binding.waitUntilFirstFrameRasterized);
  final view = binding.platformDispatcher.implicitView;
  await waitForStableFrames(
    nextFrame:
        nextFrame ??
        () {
          binding.scheduleFrame();
          return binding.endOfFrame;
        },
    size: size ?? () => view?.physicalSize,
  );
}

/// Waits for [frames] produced frames in a row at an unchanged window size.
///
/// Frame timings are reported in batches (up to a second apart in release),
/// so this counts produced frames instead. A window restored maximised is
/// resized only when it is shown, right after the first frame; the count
/// restarts on every size change so the reveal waits for frames at the final
/// size. Gives up after [cap]. Returns the number of frames waited.
@visibleForTesting
Future<int> waitForStableFrames({
  required Future<void> Function() nextFrame,
  required Size? Function() size,
  int frames = revealAfterRasterizedFrames,
  Duration cap = revealWaitCap,
  DateTime Function() now = DateTime.now,
}) async {
  var last = size();
  var stable = 0;
  var waited = 0;
  final deadline = now().add(cap);
  while (stable < frames && now().isBefore(deadline)) {
    await nextFrame();
    waited++;
    final current = size();
    if (current == last) {
      stable++;
    } else {
      last = current;
      stable = 0;
    }
  }
  return waited;
}
