import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_button.dart';
import 'package:linefm_radio/services/cast/cast_handoff.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/cast/chrome_cast_service.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/in_memory_prefs_store.dart';
import '../../support/service_doubles.dart';
import '../../support/test_doubles.dart';
import 'cast_helpers.dart';

void main() {
  final station = stationsCatalog.first;
  final other = stationsCatalog[1];

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
      service = ChromeCastService(backend: backend, resolveStreamUrl: url);
      stops = 0;
      active = station;
      track = a;
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
      await service.connect(tv);
      await settle();
      await settle();
      expect(stops, 1);
      expect(backend.loads.single.title, 'Song A');
      expect(backend.loads.single.stationName, station.displayName);
    });

    test('Titelwechsel wandert als Metadaten zum Gerät', () async {
      await service.connect(tv);
      await settle();
      handoff.onTrack(b);
      await settle();
      await settle();
      expect(backend.loads.last.title, 'Song B');
    });

    test('ohne Sitzung passiert bei Titelwechsel nichts', () async {
      handoff.onTrack(b);
      await settle();
      expect(backend.loads, isEmpty);
    });

    test('lokaler Start während Cast geht zum Gerät (Senderwechsel)', () async {
      await service.connect(tv);
      await settle();
      await settle();
      stops = 0;
      active = other;
      handoff.onLocalState(
        PlayerUiState(
          status: PlayerStatus.connecting,
          station: other,
          volume: 0.5,
        ),
      );
      await settle();
      await settle();
      expect(stops, 1);
      expect(backend.loads.last.stationName, other.displayName);
    });

    test('Lautstärke des Players geht an das Cast-Gerät', () async {
      await service.connect(tv);
      await settle();
      handoff.onLocalState(const PlayerUiState(volume: 0.5));
      expect(backend.volumes, isEmpty);
      handoff.onLocalState(const PlayerUiState(volume: 0.8));
      await settle();
      expect(backend.volumes, <double>[0.8]);
    });

    test('nach Sitzungsende bleibt lokal alles still', () async {
      await service.connect(tv);
      await settle();
      await service.disconnect();
      await settle();
      final stopsBefore = stops;
      handoff.onTrack(b);
      handoff.onLocalState(
        PlayerUiState(
          status: PlayerStatus.playing,
          station: station,
          volume: 0.5,
        ),
      );
      await settle();
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
            ...noopServiceOverrides(cast: false),
            castServiceProvider.overrideWith(createCastService),
          ],
        );
        addTearDown(container.dispose);
        final service = container.read(castServiceProvider);
        expect(service, isA<NoopCastService>());
        expect(service.state.available, isFalse);
      },
    );

    test('mit Backend: echter Dienst, Zustand erreicht den Player, '
        'Sitzung uebergibt den Sender mit Titel', () async {
      final backend = FakeCastBackend();
      castBackend = backend;
      addTearDown(() => castBackend = null);
      final container = ProviderContainer(
        overrides: <Override>[
          ...noopServiceOverrides(cast: false),
          prefsProvider.overrideWithValue(InMemoryPrefsStore()),
          ...offlineDataOverrides(),
          castServiceProvider.overrideWith(createCastService),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(castServiceProvider);
      expect(service, isA<ChromeCastService>());
      backend.setDevices(const <CastDevice>[tv]);
      await service.connect(tv);
      await settle();
      await settle();
      expect(container.read(castPlaybackProvider).isCasting, isTrue);
      expect(backend.loads, isNotEmpty, reason: 'Uebergabe lokal -> Cast');
      expect(
        backend.loads.last.title,
        isNotEmpty,
        reason: 'Titel oder Sendername als Metadaten',
      );
    });
  });

  group('Cast erst nach Tippen', () {
    final defaultFactory = castBackendFactory;
    tearDown(() {
      castBackend = null;
      castBackendFactory = defaultFactory;
      resetCastInitForTest();
    });

    testWidgets('Android ohne SDK: Knopf sichtbar, Tippen startet SDK', (
      tester,
    ) async {
      castBackend = null;
      resetCastInitForTest();
      final backend = FakeCastBackend()..setDevices(const <CastDevice>[tv]);
      var starts = 0;
      castBackendFactory = () async {
        starts++;
        return backend;
      };
      final container = ProviderContainer(
        overrides: <Override>[
          ...noopServiceOverrides(cast: false),
          prefsProvider.overrideWithValue(InMemoryPrefsStore()),
          ...offlineDataOverrides(),
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
      expect(find.byIcon(Icons.cast), findsOneWidget);
      expect(starts, 0, reason: 'vor dem Tippen kein SDK-Start');
      expect(container.read(castServiceProvider), isA<NoopCastService>());
      await tester.tap(find.byIcon(Icons.cast));
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(container.read(castServiceProvider), isA<ChromeCastService>());
      expect(find.byType(CastSheet), findsOneWidget);
      expect(find.text('Wohnzimmer'), findsOneWidget);
    });

    Future<ProviderContainer> pumpButton(WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: <Override>[
          ...noopServiceOverrides(cast: false),
          prefsProvider.overrideWithValue(InMemoryPrefsStore()),
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
      return container;
    }

    for (final (label, factory) in <(String, Future<CastBackend?> Function())>[
      ('SDK returns no context', () async => null),
      ('SDK throws', () async => throw PlatformException(code: 'no_gms')),
    ]) {
      testWidgets('Android without Play services ($label): message, button '
          'hidden, no crash', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        castBackend = null;
        resetCastInitForTest();
        castBackendFactory = factory;
        final container = await pumpButton(tester);
        expect(find.byIcon(Icons.cast), findsOneWidget);
        await tester.tap(find.byIcon(Icons.cast));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.textContaining('Google-Play-Dienste'),
          findsOneWidget,
          reason: 'understandable message instead of an empty sheet',
        );
        expect(find.byType(CastSheet), findsNothing);
        expect(find.byIcon(Icons.cast), findsNothing);
        expect(container.read(castServiceProvider), isA<NoopCastService>());
        // The player keeps working: casting calls are harmless no-ops.
        final service = container.read(castServiceProvider);
        await service.cast(stationsCatalog.first, a);
        await service.setVolume(0.5);
        expect(service.state.isCasting, isFalse);
      });
    }
  });
}
