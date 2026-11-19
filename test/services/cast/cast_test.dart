import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/platform/airplay_button.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_button.dart';
import 'package:linefm_radio/services/cast/cast_handoff.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/cast/chrome_cast_service.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

const CastDevice _tv = CastDevice(id: 'tv', name: 'Wohnzimmer');
const CastDevice _speaker = CastDevice(id: 'sp', name: 'Küche');

/// Fake-Sitzung: ersetzt das Plugin.
class FakeCastBackend implements CastBackend {
  final StreamController<List<CastDevice>> _devices =
      StreamController<List<CastDevice>>.broadcast(sync: true);
  final StreamController<CastLinkState> _links =
      StreamController<CastLinkState>.broadcast(sync: true);
  List<CastDevice> _list = <CastDevice>[];
  CastLinkState _link = CastLinkState.none;

  final List<CastMedia> loads = <CastMedia>[];
  final List<double> volumes = <double>[];
  final List<bool> scans = <bool>[];
  int endCalls = 0;
  bool startResult = true;
  Completer<void>? loadGate;

  void setDevices(List<CastDevice> list) {
    _list = list;
    _devices.add(list);
  }

  void setLink(CastLinkState link) {
    _link = link;
    _links.add(link);
  }

  @override
  List<CastDevice> get devices => _list;

  @override
  Stream<List<CastDevice>> get devicesStream => _devices.stream;

  @override
  CastLinkState get link => _link;

  @override
  Stream<CastLinkState> get linkStream => _links.stream;

  @override
  Future<void> startDiscovery({bool activeScan = false}) async =>
      scans.add(activeScan);

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<bool> startSession(CastDevice device) async {
    if (startResult) {
      setLink(const CastLinkState(CastLink.connecting, _tv));
      setLink(CastLinkState(CastLink.connected, device));
    }
    return startResult;
  }

  @override
  Future<void> endSession() async {
    endCalls++;
    setLink(CastLinkState.none);
  }

  @override
  Future<void> load(CastMedia media) async {
    final gate = loadGate;
    if (gate != null) await gate.future;
    loads.add(media);
  }

  @override
  void setVolume(double volume) => volumes.add(volume);

  @override
  Future<void> dispose() async {}
}

Future<Uri> _url(Station s) async =>
    Uri.parse('https://stream.laut.fm/${s.slug}');

const Track _a = Track(
  artist: 'Artist A',
  title: 'Song A',
  artworkUrl: 'https://cdn.example/a.jpg',
);
const Track _b = Track(artist: 'Artist B', title: 'Song B');

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  final station = stationsCatalog.first;
  final other = stationsCatalog[1];

  group('ChromeCastService', () {
    late FakeCastBackend backend;
    late ChromeCastService service;

    setUp(() {
      backend = FakeCastBackend();
      service = ChromeCastService(backend: backend, resolveStreamUrl: _url);
    });

    tearDown(() => service.dispose());

    test('Zustand: verfügbar, Geräte folgen der Suche', () async {
      expect(service.state.available, isTrue);
      expect(service.state.devices, isEmpty);
      backend.setDevices(<CastDevice>[_tv, _speaker]);
      expect(service.state.devices, hasLength(2));
      expect(service.state.isCasting, isFalse);
    });

    test('states liefert zuerst den aktuellen Zustand', () async {
      backend.setDevices(<CastDevice>[_tv]);
      final first = await service.states.first;
      expect(first.devices, <CastDevice>[_tv]);
    });

    test('connect baut die Sitzung auf, disconnect beendet sie', () async {
      backend.setDevices(<CastDevice>[_tv]);
      await service.connect(_tv);
      expect(service.state.connectedDevice, _tv);
      expect(service.state.isCasting, isTrue);
      await service.disconnect();
      expect(backend.endCalls, 1);
      expect(service.state.isCasting, isFalse);
    });

    test('connecting wird sichtbar, ist aber noch kein Casting', () async {
      backend.setLink(const CastLinkState(CastLink.connecting, _tv));
      expect(service.state.connecting, isTrue);
      expect(service.state.isCasting, isFalse);
    });

    test('Fehlstart der Sitzung ändert den Zustand nicht', () async {
      backend.startResult = false;
      await service.connect(_tv);
      expect(service.state.isCasting, isFalse);
    });

    test('cast lädt MP3-Live-Stream mit Titel, Künstler und Cover', () async {
      await service.connect(_tv);
      await service.cast(station, _a);
      expect(backend.loads, hasLength(1));
      final media = backend.loads.single;
      expect(
        media.streamUrl,
        Uri.parse('https://stream.laut.fm/${station.slug}'),
      );
      expect(media.title, 'Song A');
      expect(media.artist, 'Artist A');
      expect(media.stationName, station.displayName);
      expect(media.imageUrl, Uri.parse('https://cdn.example/a.jpg'));
    });

    test('ohne Titel: Sender als Titel, Senderlogo als Cover', () async {
      await service.connect(_tv);
      await service.cast(station, null);
      final media = backend.loads.single;
      expect(media.title, station.displayName);
      expect(media.artist, 'LINEFM');
      expect(media.imageUrl.toString(), station.logoUrl);
    });

    test('ohne Sitzung wird nichts geladen', () async {
      await service.cast(station, _a);
      expect(backend.loads, isEmpty);
    });

    test(
      'updateTrack zieht Metadaten nach, gleicher Titel nicht doppelt',
      () async {
        await service.connect(_tv);
        await service.cast(station, _a);
        await service.updateTrack(station, _b);
        await service.updateTrack(station, _b);
        expect(backend.loads.map((m) => m.title), <String>['Song A', 'Song B']);
      },
    );

    test(
      'updateTrack für einen nie übergebenen Sender wird ignoriert',
      () async {
        await service.connect(_tv);
        await service.cast(station, _a);
        await service.updateTrack(other, _b);
        expect(backend.loads, hasLength(1));
      },
    );

    test('schnelle Wechsel: Zwischenstände werden übersprungen', () async {
      await service.connect(_tv);
      final gate = backend.loadGate = Completer<void>();
      final first = service.cast(station, _a);
      await _settle();
      unawaited(
        service.updateTrack(station, const Track(artist: 'X', title: 'x1')),
      );
      unawaited(service.updateTrack(station, _b));
      gate.complete();
      await first;
      await _settle();
      expect(backend.loads.map((m) => m.title), <String>['Song A', 'Song B']);
    });

    test(
      'Sitzungsende verwirft offene Wünsche und das geladene Medium',
      () async {
        await service.connect(_tv);
        await service.cast(station, _a);
        await service.disconnect();
        await service.updateTrack(station, _b);
        expect(backend.loads, hasLength(1));
        // Neue Sitzung lädt erneut, auch denselben Titel.
        await service.connect(_tv);
        await service.cast(station, _a);
        expect(backend.loads, hasLength(2));
      },
    );

    test('setVolume geht nur bei Sitzung an das Gerät', () async {
      await service.setVolume(0.4);
      expect(backend.volumes, isEmpty);
      await service.connect(_tv);
      await service.setVolume(0.4);
      await service.setVolume(3);
      expect(backend.volumes, <double>[0.4, 1.0]);
    });

    test('Suche reicht activeScan durch', () async {
      await service.startDiscovery();
      await service.startDiscovery(activeScan: true);
      expect(backend.scans, <bool>[false, true]);
    });

    test('Ladefehler beendet den Dienst nicht', () async {
      final failing = ChromeCastService(
        backend: backend,
        resolveStreamUrl: (_) => throw StateError('offline'),
      );
      addTearDown(failing.dispose);
      await service.connect(_tv);
      await failing.cast(station, _a);
      expect(backend.loads, isEmpty);
    });
  });

  group('buildCastMedia', () {
    test('http-Cover werden nicht an den Receiver gegeben', () {
      final media = buildCastMedia(
        station,
        const Track(artist: 'A', title: 'T', artworkUrl: 'http://x/y.jpg'),
        Uri.parse('https://s/x'),
      );
      expect(media.imageUrl.toString(), station.logoUrl);
    });
  });

  group('CastHandoff', () {
    late FakeCastBackend backend;
    late ChromeCastService service;
    late CastHandoff handoff;
    late int stops;
    late Station active;
    late Track? track;
    late StreamSubscription<CastState> sub;

    setUp(() {
      backend = FakeCastBackend();
      service = ChromeCastService(backend: backend, resolveStreamUrl: _url);
      stops = 0;
      active = station;
      track = _a;
      handoff = CastHandoff(
        service: service,
        stopLocal: () async => stops++,
        activeStation: () => active,
        currentTrack: () => track,
        initialVolume: 0.5,
      );
      sub = service.states.listen(handoff.onCastState);
    });

    tearDown(() async {
      await sub.cancel();
      await service.dispose();
    });

    test('Sitzung steht: lokal stoppen, Sender mit Titel übergeben', () async {
      await service.connect(_tv);
      await _settle();
      await _settle();
      expect(stops, 1);
      expect(backend.loads.single.title, 'Song A');
      expect(backend.loads.single.stationName, station.displayName);
    });

    test('Titelwechsel wandert als Metadaten zum Gerät', () async {
      await service.connect(_tv);
      await _settle();
      handoff.onTrack(_b);
      await _settle();
      await _settle();
      expect(backend.loads.last.title, 'Song B');
    });

    test('ohne Sitzung passiert bei Titelwechsel nichts', () async {
      handoff.onTrack(_b);
      await _settle();
      expect(backend.loads, isEmpty);
    });

    test('lokaler Start während Cast geht zum Gerät (Senderwechsel)', () async {
      await service.connect(_tv);
      await _settle();
      await _settle();
      stops = 0;
      active = other;
      handoff.onLocalState(
        PlayerUiState(
          status: PlayerStatus.connecting,
          station: other,
          volume: 0.5,
        ),
      );
      await _settle();
      await _settle();
      expect(stops, 1);
      expect(backend.loads.last.stationName, other.displayName);
    });

    test('Lautstärke des Players geht an das Cast-Gerät', () async {
      await service.connect(_tv);
      await _settle();
      handoff.onLocalState(const PlayerUiState(volume: 0.5));
      expect(backend.volumes, isEmpty);
      handoff.onLocalState(const PlayerUiState(volume: 0.8));
      await _settle();
      expect(backend.volumes, <double>[0.8]);
    });

    test('nach Sitzungsende bleibt lokal alles still', () async {
      await service.connect(_tv);
      await _settle();
      await service.disconnect();
      await _settle();
      final stopsBefore = stops;
      handoff.onTrack(_b);
      handoff.onLocalState(
        PlayerUiState(
          status: PlayerStatus.playing,
          station: station,
          volume: 0.5,
        ),
      );
      await _settle();
      expect(stops, stopsBefore);
      expect(backend.loads, hasLength(1));
    });
  });

  group('createCastService', () {
    test(
      'ohne Backend (Web, Desktop, ohne Play-Dienste): Noop, nie verfügbar',
      () {
        castBackend = null;
        final container = ProviderContainer(
          overrides: <Override>[
            castServiceProvider.overrideWith(createCastService),
          ],
        );
        addTearDown(container.dispose);
        final service = container.read(castServiceProvider);
        expect(service, isA<NoopCastService>());
        expect(service.state.available, isFalse);
      },
    );
  });

  group('AirPlay', () {
    const channel = MethodChannel('test/airplay');
    final messenger =
        TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger;

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(channel, null);
    });

    test('Android/Desktop/Web: immer aus', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      messenger.setMockMethodCallHandler(channel, (_) async => true);
      expect(await airPlayAvailable(channel), isFalse);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(await airPlayAvailable(channel), isFalse);
    });

    test('iOS ohne native Umsetzung: aus', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await airPlayAvailable(channel), isFalse);
    });

    test('iOS/macOS mit nativer Umsetzung: an', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return call.method == 'isAvailable';
      });
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await airPlayAvailable(channel), isTrue);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(await airPlayAvailable(channel), isTrue);
    });
  });

  group('CastButton', () {
    Future<void> pump(WidgetTester tester, CastService service) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            prefsProvider.overrideWithValue(InMemoryPrefsStore()),
            castServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            theme: buildLinefmTheme(Brightness.dark),
            locale: const Locale('de'),
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
    }

    testWidgets('Noop: kein Knopf', (tester) async {
      await pump(tester, const NoopCastService());
      expect(find.byIcon(Icons.cast), findsNothing);
    });

    testWidgets('verfügbar ohne Geräte: kein Knopf', (tester) async {
      final backend = FakeCastBackend();
      final service = ChromeCastService(
        backend: backend,
        resolveStreamUrl: _url,
      );
      addTearDown(service.dispose);
      await pump(tester, service);
      expect(find.byIcon(Icons.cast), findsNothing);
    });

    testWidgets('Geräte da: Knopf, Sheet verbindet', (tester) async {
      final backend = FakeCastBackend();
      final service = ChromeCastService(
        backend: backend,
        resolveStreamUrl: _url,
      );
      addTearDown(service.dispose);
      await pump(tester, service);
      backend.setDevices(<CastDevice>[_tv]);
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.cast), findsOneWidget);

      await tester.tap(find.byIcon(Icons.cast));
      await tester.pumpAndSettle();
      expect(find.text('Wohnzimmer'), findsOneWidget);
      expect(backend.scans, contains(true));

      await tester.tap(find.text('Wohnzimmer'));
      await tester.pumpAndSettle();
      expect(service.state.connectedDevice, _tv);
      expect(find.byIcon(Icons.cast_connected), findsOneWidget);
    });
  });
}
