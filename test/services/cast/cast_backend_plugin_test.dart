// Host tests for the flutter_chrome_cast adapter. On the test host
// Platform.isAndroid is false, so the plugin talks over its iOS method
// channels; the tests answer them with mock handlers.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_backend_plugin.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';

const _context = MethodChannel('google_cast.context');
const _discovery = MethodChannel('google_cast.discovery_manager');
const _session = MethodChannel('google_cast.session_manager');
const _media = MethodChannel('google_cast.remote_media_client');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String, List<MethodCall>>{};
  Object? contextResult = true;

  void record(MethodChannel channel, [Object? Function(MethodCall)? answer]) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.putIfAbsent(channel.name, () => <MethodCall>[]).add(call);
      return answer?.call(call);
    });
  }

  setUp(() {
    calls.clear();
    contextResult = true;
    record(_context, (_) {
      final r = contextResult;
      if (r is Exception) throw r;
      return r;
    });
    record(_discovery);
    record(_session, (_) => true);
    record(_media);
  });

  tearDown(() {
    for (final c in [_context, _discovery, _session, _media]) {
      messenger.setMockMethodCallHandler(c, null);
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test('returns null on platforms without Cast', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(await createPluginBackend(), isNull);
    expect(calls, isEmpty);
  });

  test('returns null when the cast context refuses', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    contextResult = false;
    expect(await createPluginBackend(), isNull);
    expect(
      calls['google_cast.context']!.single.method,
      'setSharedInstanceWithOptions',
    );
  });

  test('returns null when the cast context throws', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    contextResult = PlatformException(code: 'no-play-services');
    expect(await createPluginBackend(), isNull);
  });

  test('backend maps state and forwards commands to the plugin', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final backend = await createPluginBackend();
    expect(backend, isNotNull);
    backend!;

    expect(backend.devices, isEmpty);
    expect(backend.link, CastLinkState.none);
    expect(backend.devicesStream, isA<Stream<List<CastDevice>>>());
    expect(backend.linkStream, isA<Stream<CastLinkState>>());

    await backend.startDiscovery(activeScan: true);
    await backend.stopDiscovery();
    expect(
      calls['google_cast.discovery_manager']!.map((c) => c.method),
      containsAllInOrder(<String>['startDiscovery', 'stopDiscovery']),
    );

    // Unknown device: no session request reaches the plugin.
    expect(
      await backend.startSession(const CastDevice(id: 'x', name: 'X')),
      isFalse,
    );

    await backend.load(
      CastMedia(
        streamUrl: Uri.parse('https://stream.example/main'),
        title: 'Song',
        artist: 'Artist',
        stationName: 'LineFM +MAIN',
        imageUrl: Uri.parse('https://img.example/cover.jpg'),
      ),
    );
    await backend.stopMedia();
    final media = calls['google_cast.remote_media_client']!;
    final load = media.firstWhere((c) => c.method == 'loadMedia');
    final args = (load.arguments as Map).cast<String, Object?>();
    expect(
      args['contentID'] ?? args['contentId'],
      'https://stream.example/main',
    );
    expect(media.map((c) => c.method), contains('stop'));

    backend.setVolume(1.7);
    await backend.endSession();
    await pumpEventQueue();
    final session = calls['google_cast.session_manager']!;
    expect(
      session.firstWhere((c) => c.method == 'setDeviceVolume').arguments,
      1.0,
    );
    expect(session.map((c) => c.method), contains('endSessionAndStopCasting'));

    await backend.dispose();
  });
}
