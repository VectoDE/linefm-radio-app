import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/player/player_actions.dart';
import 'package:linefm_radio/features/player/player_screen.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/services/share/share_service.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_doubles.dart';

class _RecordingHub extends TelemetryHub {
  _RecordingHub() : super(config: const AppConfig());

  final List<(String, Map<String, Object>)> events =
      <(String, Map<String, Object>)>[];

  @override
  Future<void> event(
    String name, [
    Map<String, Object> props = const <String, Object>{},
  ]) async {
    events.add((name, props));
  }

  List<String> get names => events.map((e) => e.$1).toList();
}

class _RecordingShare implements ShareService {
  final List<Track> shared = <Track>[];
  final List<Uri> opened = <Uri>[];

  @override
  Future<void> shareSong(Station station, Track track) async =>
      shared.add(track);

  @override
  Future<void> shareText(String text) async {}

  @override
  Future<void> openUrl(Uri uri) async => opened.add(uri);

  @override
  Future<void> exportFavorites(
    List<Favorite> favorites,
    ExportFormat format,
  ) async {}
}

const _track = Track(artist: 'James Hype', title: "I Was Lovin' You");

class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(InMemoryPrefsStore()),
        // Hoererzahl eingeschaltet (features.yaml), Standard waere aus.
        appConfigProvider.overrideWithValue(
          const AppConfig(showListenerCount: true),
        ),
        telemetryProvider.overrideWithValue(hub),
        shareServiceProvider.overrideWithValue(share),
        playbackServiceProvider.overrideWithValue(playback),
        nowPlayingRepositoryProvider.overrideWithValue(
          FakeNowPlayingRepository(
            tracks: <String, Track>{
              for (final s in stationsCatalog) s.slug: _track,
            },
            listeners: 1234,
          ),
        ),
      ],
    );
  }

  final hub = _RecordingHub();
  final share = _RecordingShare();
  final playback = NoopPlaybackService();
  late final ProviderContainer container;

  Widget app({double width = 390, double height = 844}) =>
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildLinefmTheme(Brightness.dark),
          locale: const Locale('de'),
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: PlayerScreen()),
        ),
      );
}

Future<void> _pump(WidgetTester tester, _Harness h) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(h.app());
  // Stationsdaten (Stream) und Hoererzahl treffen asynchron ein.
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('Hilfsfunktionen', () {
    test('secondsBucket: grobe Klassen', () {
      expect(secondsBucket(0), '<10');
      expect(secondsBucket(9), '<10');
      expect(secondsBucket(10), '10-59');
      expect(secondsBucket(60), '60-299');
      expect(secondsBucket(300), '300-899');
      expect(secondsBucket(900), '900-1799');
      expect(secondsBucket(1800), '1800-3599');
      expect(secondsBucket(7200), '3600+');
    });

    test('neighborStation: rundum in beide Richtungen', () {
      final first = stationsCatalog.first;
      final last = stationsCatalog.last;
      expect(neighborStation(first, 1), stationsCatalog[1]);
      expect(neighborStation(first, -1), last);
      expect(neighborStation(last, 1), first);
    });
  });

  group('PlayerScreen', () {
    testWidgets('zeigt Titel, Kuenstler, Hoererzahl und Knoepfe', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      await _pump(tester, h);

      expect(find.text("I WAS LOVIN' YOU"), findsOneWidget);
      expect(find.text('James Hype'), findsOneWidget);
      expect(find.text('1234 hören gerade zu'), findsOneWidget);
      expect(find.bySemanticsLabel('Stream starten'), findsOneWidget);
      expect(find.bySemanticsLabel('Song merken'), findsOneWidget);
      expect(find.bySemanticsLabel('Zufälligen Sender abspielen'), findsOne);
      expect(find.bySemanticsLabel('Song öffnen in …'), findsOneWidget);
      expect(find.bySemanticsLabel('Song teilen'), findsOneWidget);
    });

    testWidgets('Play startet, Stop meldet Hoerdauer als Klasse', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      await _pump(tester, h);

      await tester.tap(find.bySemanticsLabel('Stream starten'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.playback.state.isPlaying, isTrue);
      expect(h.hub.events.first.$1, 'play');
      expect(h.hub.events.first.$2['station'], 'linefm');

      await tester.tap(find.bySemanticsLabel('Stream stoppen'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.playback.state.isPlaying, isFalse);
      final stop = h.hub.events.last;
      expect(stop.$1, 'stop');
      expect(stop.$2['station'], 'linefm');
      expect(stop.$2['seconds_bucket'], '<10');
    });

    testWidgets('Herz merkt den Song und entfernt ihn wieder', (tester) async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      await _pump(tester, h);

      await tester.tap(find.bySemanticsLabel('Song merken'));
      await tester.pump(const Duration(milliseconds: 400));
      final saved = h.container.read(favoritesProvider);
      expect(saved, hasLength(1));
      expect(saved.single.key, "linefm:james hype:i was lovin' you");
      expect(find.bySemanticsLabel('Aus Favoriten entfernen'), findsOne);

      await tester.tap(find.bySemanticsLabel('Aus Favoriten entfernen'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.container.read(favoritesProvider), isEmpty);
      expect(h.hub.names, <String>['favorite_add', 'favorite_remove']);
    });

    testWidgets('Shuffle waehlt eine andere Station und spielt', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      await _pump(tester, h);
      final before = h.container.read(activeStationProvider);

      await tester.tap(find.bySemanticsLabel('Zufälligen Sender abspielen'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(h.container.read(activeStationProvider), isNot(before));
      expect(h.playback.state.isPlaying, isTrue);
      expect(h.hub.names, contains('shuffle'));
    });

    testWidgets('Wischen links/rechts wechselt den Sender', (tester) async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      await _pump(tester, h);

      await tester.fling(
        find.text("I WAS LOVIN' YOU"),
        const Offset(-300, 0),
        1500,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.container.read(activeStationProvider), stationsCatalog[1]);
      // Nicht gespielt: nur gewaehlt, kein play-Ereignis.
      expect(h.playback.state.isPlaying, isFalse);
      expect(h.hub.names, isNot(contains('play')));

      await tester.fling(
        find.text("I WAS LOVIN' YOU"),
        const Offset(300, 0),
        1500,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.container.read(activeStationProvider), stationsCatalog.first);
    });

    testWidgets('Wischen waehrend der Wiedergabe spielt den neuen Sender', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      await _pump(tester, h);

      await tester.tap(find.bySemanticsLabel('Stream starten'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.fling(
        find.text("I WAS LOVIN' YOU"),
        const Offset(-300, 0),
        1500,
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(h.playback.state.station, stationsCatalog[1]);
      expect(h.playback.state.isPlaying, isTrue);
    });

    testWidgets('Teilen und Musikdienst-Sheet', (tester) async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      await _pump(tester, h);

      await tester.tap(find.bySemanticsLabel('Song teilen'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.share.shared, <Track>[_track]);
      expect(h.hub.names, contains('share_song'));

      await tester.tap(find.bySemanticsLabel('Song öffnen in …'));
      await tester.pumpAndSettle();
      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('YouTube Music'), findsOneWidget);
      expect(find.text('Apple Music'), findsOneWidget);

      await tester.tap(find.text('Spotify'));
      await tester.pumpAndSettle();
      expect(h.share.opened.single.host, 'open.spotify.com');
    });

    testWidgets('Screenreader: Aktionen fuer Sender-Wechsel', (tester) async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      final handle = tester.ensureSemantics();
      await _pump(tester, h);

      final root = tester.getSemantics(find.text('James Hype'));
      expect(root, isNotNull);
      final actions = <String>{};
      SemanticsNode? node = root;
      while (node != null) {
        final data = node.getSemanticsData();
        for (final id in data.customSemanticsActionIds ?? const <int>[]) {
          actions.add(CustomSemanticsAction.getAction(id)!.label!);
        }
        node = node.parent;
      }
      expect(
        actions,
        containsAll(<String>[
          'Nächster Sender',
          'Vorheriger Sender',
          'Player schließen',
        ]),
      );
      handle.dispose();
    });

    testWidgets('Jeder Knopf ist ein eigener, fokussierbarer Knoten', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      final handle = tester.ensureSemantics();
      await _pump(tester, h);

      // Im Web wird nur ein eigener, fokussierbarer Semantik-Knoten zu einem
      // DOM-Element. Fehlt er, bleibt der Browser-Fokus beim Tabben auf dem
      // vorigen Knopf stehen (doppelter Tab-Stopp).
      for (final label in <String>[
        'Zufälligen Sender abspielen',
        'Stream starten',
        'Song merken',
        'Song öffnen in …',
        'Song teilen',
      ]) {
        final data = tester
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData();
        expect(data.label, label, reason: '$label: eigener Knoten');
        expect(
          data.hasAction(SemanticsAction.focus),
          isTrue,
          reason: '$label: onFocus fuer den Browser-Fokus',
        );
      }
      handle.dispose();
    });

    testWidgets('Pfeiltasten wechseln den Sender (eingebettet)', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp(
            theme: buildLinefmTheme(Brightness.dark),
            locale: const Locale('de'),
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: PlayerScreen(embedded: true)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.container.read(activeStationProvider), stationsCatalog[1]);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.container.read(activeStationProvider), stationsCatalog.first);
    });
  });
}
