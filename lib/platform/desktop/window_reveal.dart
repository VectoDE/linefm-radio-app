import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Channel to the Windows runner (windows/runner/flutter_window.cpp).
const MethodChannel windowRevealChannel = MethodChannel(
  'de.linefm.app/window_reveal',
);

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
  try {
    await (presented ?? _loaderPresented)();
    await channel.invokeMethod<void>('reveal');
  } on Object catch (e) {
    debugPrint('Window reveal signal failed: $e');
  }
}

/// First rasterised frame plus one more frame.
Future<void> _loaderPresented() async {
  final binding = WidgetsBinding.instance;
  await binding.waitUntilFirstFrameRasterized;
  binding.scheduleFrame();
  await binding.endOfFrame;
}
