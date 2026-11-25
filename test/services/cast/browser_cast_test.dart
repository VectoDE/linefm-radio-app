import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/features/consent/cast_consent.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/cast/browser_cast.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_button.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/cast/chrome_cast_service.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Fake for web/cast.js: no real Google script, no real Cast device.
class FakeBrowserCastBridge implements BrowserCastBridge {
  FakeBrowserCastBridge({this.supported = true, this.decision});

  @override
  bool supported;

  @override
  bool? decision;

  final List<void Function()> _listeners = <void Function()>[];
  int sdkLoads = 0;
  bool sdkResult = true;
  int sessionRequests = 0;
  int sessionEnds = 0;
  int stops = 0;
  int resets = 0;
  final List<Map<String, String?>> loads = <Map<String, String?>>[];
  final List<double> volumes = <double>[];

  String state = '';
  String id = '';
  String name = '';

  void emit(String next, {String device = '', String label = ''}) {
    state = next;
    name = device;
    id = label;
    for (final l in List<void Function()>.of(_listeners)) {
      l();
    }
  }

  @override
  void grant() => decision = true;

  @override
  void deny() => decision = false;

  @override
  void reset() {
    resets++;
    decision = null;
  }

  @override
  Future<bool> loadSdk() async {
    sdkLoads++;
    if (sdkResult) state = 'NOT_CONNECTED';
    return sdkResult;
  }

  @override
  void onChange(void Function() listener) => _listeners.add(listener);

  @override
  String get castState => state;

  @override
  String get deviceId => id;

  @override
  String get deviceName => name;

  @override
  Future<bool> requestSession() async {
    sessionRequests++;
    emit('CONNECTED', device: 'Wohnzimmer TV', label: 'abc');
    return true;
  }

  @override
  void endSession() {
    sessionEnds++;
    emit('NOT_CONNECTED');
  }

  @override
  Future<bool> loadMedia({
    required String url,
    required String contentType,
    required String title,
    required String artist,
    required String album,
    String? imageUrl,
  }) async {
    loads.add(<String, String?>{
      'url': url,
      'type': contentType,
      'title': title,
      'artist': artist,
      'album': album,
      'image': imageUrl,
    });
    return true;
  }

  @override
  Future<void> stopMedia() async => stops++;

  @override
  void setVolume(double volume) => volumes.add(volume);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

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
      await _settle();
      expect(backend.devices, const <CastDevice>[browserPickerDevice]);
      expect(seen, hasLength(1));
      bridge.emit('NO_DEVICES_AVAILABLE');
      await _settle();
      expect(backend.devices, isEmpty);
    });

    test('session state maps to the link with the device name', () async {
      final links = <CastLinkState>[];
      backend.linkStream.listen(links.add);
      bridge.emit('CONNECTING');
      await _settle();
      expect(backend.link.link, CastLink.connecting);
      final ok = await backend.startSession(browserPickerDevice);
      await _settle();
      expect(ok, isTrue);
      expect(bridge.sessionRequests, 1);
      expect(backend.link.link, CastLink.connected);
      expect(backend.link.device!.name, 'Wohnzimmer TV');
      await backend.endSession();
      await _settle();
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
      await _settle();
      expect(service.state.available, isTrue);
      await service.connect(service.state.devices.single);
      await _settle();
      expect(service.state.isCasting, isTrue);
      expect(service.state.connectedDevice!.name, 'Wohnzimmer TV');
    });
  });

  group('CastConsentNotifier', () {
    test('null when the browser cannot cast', () {
      final c = ProviderContainer(
        overrides: <Override>[
          browserCastBridgeProvider.overrideWithValue(
            FakeBrowserCastBridge(supported: false, decision: true),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(castConsentProvider), isNull);
      c.read(castConsentProvider.notifier).set(value: true);
      expect(c.read(castConsentProvider), isNull);
    });

    test('grant, deny and reset go to the bridge', () {
      final bridge = FakeBrowserCastBridge();
      final c = ProviderContainer(
        overrides: <Override>[
          browserCastBridgeProvider.overrideWithValue(bridge),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(castConsentProvider), isNull);
      c.read(castConsentProvider.notifier).set(value: true);
      expect(bridge.decision, isTrue);
      expect(c.read(castConsentProvider), isTrue);
      c.read(castConsentProvider.notifier).set(value: false);
      expect(bridge.decision, isFalse);
      c.read(castConsentProvider.notifier).reset();
      expect(bridge.resets, 1);
      expect(c.read(castConsentProvider), isNull);
    });
  });

  group('CastButton on the web', () {
    final defaultFactory = castBackendFactory;
    tearDown(() {
      castBackend = null;
      castBackendFactory = defaultFactory;
      resetCastInitForTest();
    });

    Future<(ProviderContainer, FakeBrowserCastBridge, List<int>)> pump(
      WidgetTester tester, {
      bool? decision,
    }) async {
      castBackend = null;
      resetCastInitForTest();
      final bridge = FakeBrowserCastBridge(decision: decision);
      final starts = <int>[];
      castBackendFactory = () async {
        starts.add(1);
        return createBrowserCastBackend(bridge);
      };
      final container = ProviderContainer(
        overrides: <Override>[
          prefsProvider.overrideWithValue(InMemoryPrefsStore()),
          browserCastBridgeProvider.overrideWithValue(bridge),
          castServiceProvider.overrideWith(createCastService),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            theme: buildLinefmTheme(Brightness.dark),
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Center(child: CastButton())),
          ),
        ),
      );
      return (container, bridge, starts);
    }

    testWidgets('button visible before consent, tap asks first', (
      tester,
    ) async {
      final (container, bridge, starts) = await pump(tester);
      expect(find.byIcon(Icons.cast), findsOneWidget);
      await tester.tap(find.byIcon(Icons.cast));
      await tester.pumpAndSettle();
      expect(find.byType(CastConsentDialog), findsOneWidget);
      expect(starts, isEmpty);
      await tester.tap(find.text('Ablehnen'));
      await tester.pumpAndSettle();
      expect(bridge.decision, isFalse);
      expect(bridge.sdkLoads, 0, reason: 'declined: nothing from Google');
      expect(starts, isEmpty);
      expect(container.read(castServiceProvider), isA<NoopCastService>());
    });

    testWidgets('allow loads the SDK and offers the browser picker', (
      tester,
    ) async {
      final (container, bridge, starts) = await pump(tester);
      await tester.tap(find.byIcon(Icons.cast));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Erlauben'));
      await tester.pumpAndSettle();
      expect(bridge.decision, isTrue);
      expect(bridge.sdkLoads, 1);
      expect(starts, hasLength(1));
      expect(container.read(castServiceProvider), isA<ChromeCastService>());
      expect(find.byType(CastSheet), findsOneWidget);
      await tester.tap(find.text('Gerät auswählen'));
      await tester.pumpAndSettle();
      expect(bridge.sessionRequests, 1);
    });

    testWidgets('earlier consent: no dialog', (tester) async {
      final (_, bridge, starts) = await pump(tester, decision: true);
      await tester.tap(find.byIcon(Icons.cast));
      await tester.pumpAndSettle();
      expect(find.byType(CastConsentDialog), findsNothing);
      expect(starts, hasLength(1));
      expect(bridge.sdkLoads, 1);
    });

    testWidgets('unsupported browser: no button', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      castBackend = null;
      resetCastInitForTest();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            prefsProvider.overrideWithValue(InMemoryPrefsStore()),
            browserCastBridgeProvider.overrideWithValue(
              FakeBrowserCastBridge(supported: false),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            theme: buildLinefmTheme(Brightness.dark),
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Center(child: CastButton())),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.cast), findsNothing);
    });
  });
}
