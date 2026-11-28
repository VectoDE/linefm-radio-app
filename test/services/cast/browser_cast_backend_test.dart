import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/cast/browser_cast.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/cast/chrome_cast_service.dart';

import 'browser_cast_helpers.dart';

void main() {
  group('createBrowserCastBackend', () {
    test('without consent nothing loads from Google', () async {
      final bridge = FakeBrowserCastBridge();
      expect(await createBrowserCastBackend(bridge), isNull);
      bridge.decision = false;
      expect(await createBrowserCastBackend(bridge), isNull);
      expect(bridge.sdkLoads, 0);
    });

    test('unsupported browser: no SDK even with consent', () async {
      final bridge = FakeBrowserCastBridge(supported: false, decision: true);
      expect(await createBrowserCastBackend(bridge), isNull);
      expect(bridge.sdkLoads, 0);
    });

    test('script fails to load: no backend', () async {
      final bridge = FakeBrowserCastBridge(decision: true)..sdkResult = false;
      expect(await createBrowserCastBackend(bridge), isNull);
      expect(bridge.sdkLoads, 1);
    });

    test('revoked consent: no backend and no further SDK load', () async {
      final bridge = FakeBrowserCastBridge(decision: true);
      final first = await createBrowserCastBackend(bridge);
      expect(first, isNotNull);
      await first!.dispose();
      bridge.deny();
      expect(await createBrowserCastBackend(bridge), isNull);
      bridge.reset();
      expect(await createBrowserCastBackend(bridge), isNull);
      expect(bridge.sdkLoads, 1);
    });

    test('with consent: backend after loading the SDK', () async {
      final bridge = FakeBrowserCastBridge(decision: true);
      final backend = await createBrowserCastBackend(bridge);
      expect(backend, isA<BrowserCastBackend>());
      expect(bridge.sdkLoads, 1);
      expect(backend!.devices, const <CastDevice>[browserPickerDevice]);
      await backend.dispose();
    });
  });

  group('BrowserCastBackend', () {
    late FakeBrowserCastBridge bridge;
    late BrowserCastBackend backend;

    setUp(() {
      bridge = FakeBrowserCastBridge(decision: true)
        ..state = 'NO_DEVICES_AVAILABLE';
      backend = BrowserCastBackend(bridge);
    });
    tearDown(() => backend.dispose());

    test('picker placeholder only while devices are in reach', () async {
      expect(backend.devices, isEmpty);
      final seen = <List<CastDevice>>[];
      backend.devicesStream.listen(seen.add);
      bridge.emit('NOT_CONNECTED');
      await settle();
      expect(backend.devices, const <CastDevice>[browserPickerDevice]);
      expect(seen, hasLength(1));
      bridge.emit('NO_DEVICES_AVAILABLE');
      await settle();
      expect(backend.devices, isEmpty);
    });

    test('session state maps to the link with the device name', () async {
      final links = <CastLinkState>[];
      backend.linkStream.listen(links.add);
      bridge.emit('CONNECTING');
      await settle();
      expect(backend.link.link, CastLink.connecting);
      final ok = await backend.startSession(browserPickerDevice);
      await settle();
      expect(ok, isTrue);
      expect(bridge.sessionRequests, 1);
      expect(backend.link.link, CastLink.connected);
      expect(backend.link.device!.name, 'Wohnzimmer TV');
      await backend.endSession();
      await settle();
      expect(bridge.sessionEnds, 1);
      expect(backend.link, CastLinkState.none);
      expect(links.map((l) => l.link), <CastLink>[
        CastLink.connecting,
        CastLink.connected,
        CastLink.disconnected,
      ]);
    });

    test(
      'load sends live stream with title, artist, station and cover',
      () async {
        await backend.load(
          CastMedia(
            streamUrl: Uri.parse('https://main.stream.laut.fm/main'),
            title: 'Song',
            artist: 'Band',
            stationName: 'LineFM +MAIN',
            imageUrl: Uri.parse('https://cdn.linefm.de/cover.jpg'),
          ),
        );
        expect(bridge.loads.single, <String, String?>{
          'url': 'https://main.stream.laut.fm/main',
          'type': 'audio/mpeg',
          'title': 'Song',
          'artist': 'Band',
          'album': 'LineFM +MAIN',
          'image': 'https://cdn.linefm.de/cover.jpg',
        });
        await backend.stopMedia();
        backend.setVolume(0.4);
        expect(bridge.stops, 1);
        expect(bridge.volumes, <double>[0.4]);
      },
    );

    test('works under ChromeCastService: connect, cast, stop', () async {
      bridge.emit('NOT_CONNECTED');
      final service = ChromeCastService(
        backend: backend,
        resolveStreamUrl: (_) async => Uri.parse('https://x.stream.laut.fm/x'),
      );
      await settle();
      expect(service.state.available, isTrue);
      await service.connect(service.state.devices.single);
      await settle();
      expect(service.state.isCasting, isTrue);
      expect(service.state.connectedDevice!.name, 'Wohnzimmer TV');
    });

    test('track change, station change, volume and stop reach the '
        'receiver', () async {
      bridge.emit('NOT_CONNECTED');
      final service = ChromeCastService(
        backend: backend,
        resolveStreamUrl: (s) async =>
            Uri.parse('https://stream.laut.fm/${s.slug}'),
      );
      addTearDown(service.dispose);
      final station = stationsCatalog.first;
      final other = stationsCatalog[1];
      await service.connect(browserPickerDevice);
      await settle();
      await service.cast(
        station,
        const Track(artist: 'Artist A', title: 'Song A'),
      );
      await service.updateTrack(
        station,
        const Track(artist: 'Artist B', title: 'Song B'),
      );
      expect(bridge.loads.map((l) => l['title']), <String>['Song A', 'Song B']);
      expect(bridge.loads.last['artist'], 'Artist B');
      expect(bridge.loads.last['album'], station.displayName);
      expect(
        bridge.loads.last['url'],
        'https://stream.laut.fm/${station.slug}',
      );
      // A track update for a station that is not on the receiver is ignored.
      await service.updateTrack(other, const Track(artist: 'X', title: 'Y'));
      expect(bridge.loads, hasLength(2));
      await service.cast(other, null);
      expect(bridge.loads.last['url'], 'https://stream.laut.fm/${other.slug}');
      expect(bridge.loads.last['title'], other.displayName);
      await service.setVolume(1.7);
      expect(bridge.volumes, <double>[1.0]);
      await service.stopMedia();
      expect(bridge.stops, 1);
      await service.disconnect();
      await settle();
      expect(bridge.sessionEnds, 1);
      expect(service.state.isCasting, isFalse);
    });

    test('device name from the SDK, fallback when it is empty', () async {
      bridge.emit('CONNECTED', device: 'Küche', label: 'k1');
      await settle();
      expect(backend.link.device!.id, 'k1');
      expect(backend.link.device!.name, 'Küche');
      bridge.emit('CONNECTED');
      await settle();
      expect(backend.link.device!.name, 'Chromecast');
    });
  });
}
