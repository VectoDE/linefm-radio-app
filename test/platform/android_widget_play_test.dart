import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Android widget play button must start playback in the background
/// (broadcast plus MediaBrowser) and never open the activity; stop stays a
/// media button broadcast. Native code cannot run in unit tests, so this
/// guards the wiring in the Kotlin source.
void main() {
  final source = File(
    'android/app/src/main/kotlin/de/linefm/app/widget/LinefmWidgetProvider.kt',
  ).readAsStringSync();

  String body(String name) {
    final start = source.indexOf('private fun $name(');
    expect(start, greaterThan(-1), reason: 'missing $name');
    return source.substring(start, source.indexOf('\n    }\n', start));
  }

  test('play is a broadcast to the provider, not an activity', () {
    final play = body('playIntent');
    expect(play, contains('PendingIntent.getBroadcast'));
    expect(play, contains('ACTION_PLAY'));
    expect(play, isNot(contains('getActivity')));
    expect(play, isNot(contains('MainActivity')));
  });

  test('the receiver plays via the audio_service session', () {
    expect(source, contains('ACTION_PLAY'));
    expect(source, contains('goAsync()'));
    expect(source, contains('MediaBrowserCompat'));
    expect(source, contains('playFromMediaId'));
  });

  test('stop stays a broadcast and the root area opens the app', () {
    expect(body('stopIntent'), contains('PendingIntent.getBroadcast'));
    expect(body('openIntent'), contains('PendingIntent.getActivity'));
  });
}
