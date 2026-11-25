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
    await (presented ?? _loaderPresented)();
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

Future<void> _loaderPresented() async {
  final binding = WidgetsBinding.instance;
  await binding.waitUntilFirstFrameRasterized;
  // Frame timings are reported in batches (up to a second apart in release),
  // so count produced frames instead. A window restored maximised is resized
  // only when it is shown, right after the first frame; the count restarts on
  // every size change so the reveal waits for frames at the final size.
  final view = binding.platformDispatcher.implicitView;
  var size = view?.physicalSize;
  var stable = 0;
  final deadline = DateTime.now().add(const Duration(milliseconds: 1500));
  while (stable < revealAfterRasterizedFrames &&
      DateTime.now().isBefore(deadline)) {
    binding.scheduleFrame();
    await binding.endOfFrame;
    final now = view?.physicalSize;
    if (now == size) {
      stable++;
    } else {
      size = now;
      stable = 0;
    }
  }
}
