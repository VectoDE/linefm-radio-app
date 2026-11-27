// Integrationstest auf Windows : die echte App in
// einem echten Fenster, mit Netzwerk-Fakes fuer laut.fm (wie in
// test/data/live/now_playing_repository_test.dart) und ohne Audio.
//
// Lauf nur in der CI (Workflow itest-windows.yml):
//   flutter test integration_test/windows_app_test.dart -d windows
//
// Die Fenster-Funktionen (window_manager) sind die echten; Tray und
// Tastenkuerzel laufen mit. Nicht geprueft werden hier Ziehen, Andocken und
// Snap-Layouts (siehe Bericht zur Änderung).
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:linefm_radio/app/app.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/data/live/now_playing_repository.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/schedule_slot.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/stations_config.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/loader/app_loader.dart';
import 'package:linefm_radio/features/player/player_screen.dart';
import 'package:linefm_radio/features/settings/settings_screen.dart';
import 'package:linefm_radio/features/stations/station_card.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/platform/desktop/desktop_controller.dart';
import 'package:linefm_radio/platform/desktop/desktop_init.dart';
import 'package:linefm_radio/platform/desktop/title_bar.dart';
import 'package:linefm_radio/platform/desktop/window_caption.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';
import 'package:window_manager/legacy.dart' show DragToMoveArea, WindowManager;

import '../test/support/test_doubles.dart';

/// Zielordner der Bilder (CI: `--dart-define=ITEST_OUT=...`).
const String _outDefine = String.fromEnvironment('ITEST_OUT');

final WindowManager _wm = WindowManager.instance;

/// Verfuegbare Werte nach Test: Bildzaehler, Ordner.
int _shotNumber = 0;
late final Directory _shotDir;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Schnelle Frames auch ohne Eingaben, damit Wartezeiten kurz bleiben.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    // Fixed station list: the tests must not depend on the operator's
    // config/stations.yaml. Same content as test/fixtures/stations/stations_6.json.
    installBundledStations(parseStationsConfig(_stationsJson));
    final out = _outDefine.isNotEmpty
        ? _outDefine
        : (Platform.environment['ITEST_OUT'] ??
              '${Directory.systemTemp.path}${Platform.pathSeparator}'
                  'windows-itest-screens');
    _shotDir = Directory(out)..createSync(recursive: true);
    // ignore: avoid_print
    print('Bilderordner: ${_shotDir.path}');
    // Echte Desktop-Umsetzung: Fenster (window_manager), Tray, Kuerzel.
    await initDesktop();
    final desktop = DesktopController.instance;
    expect(
      desktop.active,
      isTrue,
      reason: 'initDesktop() hat die Desktop-Umsetzung nicht gestartet',
    );
    // ignore: avoid_print
    print(
      'Titelleiste: ${desktop.caption.style}, '
      'Tray verfuegbar: ${desktop.tray.isAvailable}',
    );
  });

  // ---------------------------------------------------------------- Rapid station switching

  testWidgets('schneller Wechsel zwischen drei Sendern zeigt Titel und '
      'Sender des zuletzt gewaehlten', (tester) async {
    await _setWindowSize(tester, const Size(1000, 680));
    final world = _World(settings: _settings(AppLanguage.de));
    await _pumpWorld(tester, world);
    final start = stationsCatalog.first;
    final rap = stationsCatalog[1];
    final gaming = stationsCatalog[2];
    final lofi = stationsCatalog[3];

    // Ausgangslage: Titel des ersten Senders steht im Player.
    await _pumpUntil(
      tester,
      () =>
          _inPlayer(find.text(_old(start).toUpperCase())).evaluate().isNotEmpty,
      'Titel von ${start.displayName} im Player',
    );
    await _shot(tester, '99-1-start-${start.slug}');

    // Ab jetzt haengen alle Antworten, bis der Test sie freigibt; die Uhr
    // des Repositories laeuft 20 Minuten weiter: die gemerkten Titel sind
    // abgelaufen und duerfen nicht mehr erscheinen.
    world.api.gated = true;
    world.clock.advance(const Duration(minutes: 20));

    await _tapStation(tester, rap);
    await tester.pump(const Duration(milliseconds: 40));
    await _tapStation(tester, gaming);
    await tester.pump(const Duration(milliseconds: 40));
    await _tapStation(tester, lofi);
    await _pumpFor(tester, const Duration(milliseconds: 600));

    expect(world.container.read(activeStationProvider), lofi);
    _expectPlayer(
      lofi,
      forbidden: <String>[for (final s in stationsCatalog) _old(s)],
    );
    expect(
      world.api.pending.keys,
      containsAll(<String>[
        'current:${rap.slug}',
        'current:${gaming.slug}',
        'current:${lofi.slug}',
      ]),
      reason: 'alle drei Abrufe haengen (Antworten stehen aus)',
    );
    await _shot(tester, '99-2-gewechselt-antworten-ausstehend');

    // Der zuletzt gewaehlte Sender antwortet zuerst.
    world.api.release('current:${lofi.slug}', world.next(lofi));
    await _pumpUntil(
      tester,
      () =>
          _inPlayer(find.text(_new(lofi).toUpperCase())).evaluate().isNotEmpty,
      'neuer Titel von ${lofi.displayName} im Player',
    );
    await _shot(tester, '99-3-antwort-des-letzten-senders');

    // Die verspaeteten Antworten der frueher gewaehlten Sender folgen.
    world.api
      ..release('current:${gaming.slug}', world.next(gaming))
      ..release('current:${rap.slug}', world.next(rap));
    await _pumpFor(tester, const Duration(milliseconds: 800));
    _expectPlayer(
      lofi,
      title: _new(lofi),
      forbidden: <String>[_new(rap), _new(gaming)],
    );
    expect(world.container.read(activeStationProvider), lofi);
    await _shot(tester, '99-4-nach-verspaeteten-antworten');

    // Restliche Antworten (Verlauf, Hoerer) freigeben; nichts aendert sich.
    for (final key in world.api.pending.keys.toList()) {
      world.api.release(key, null);
    }
    await _pumpFor(tester, const Duration(milliseconds: 500));
    _expectPlayer(lofi, title: _new(lofi));

    // Zurueck zu einem der frueheren Sender: dessen eigener, neuer Titel.
    world.api.gated = false;
    await _tapStation(tester, rap);
    await _pumpUntil(
      tester,
      () => _inPlayer(find.text(_new(rap).toUpperCase())).evaluate().isNotEmpty,
      'Titel von ${rap.displayName} nach Rueckwechsel',
    );
    _expectPlayer(rap, title: _new(rap), forbidden: <String>[_new(lofi)]);
    await _shot(tester, '99-5-rueckwechsel-${rap.slug}');

    await _disposeWorld(tester, world);
  }, timeout: const Timeout(Duration(minutes: 4)));

  // --------------------------------------------------------------- Language switch

  testWidgets('Sprache de/en umschalten, Rail-Breite bleibt 104', (
    tester,
  ) async {
    expect(LinefmMetrics.railWidth, 104);
    for (final width in <double>[880, 1000]) {
      await _setWindowSize(tester, Size(width, 720));
      final world = _World(settings: _settings(AppLanguage.de));
      await _pumpWorld(tester, world);

      // Einstellungen ueber das Zahnrad im Header oeffnen (nicht in der Rail).
      final rail = find.byKey(const ValueKey<String>('shell-rail'));
      expect(rail, findsOneWidget);
      await tester.tap(find.byIcon(FontAwesomeIcons.gear.data));
      await _pumpFor(tester, const Duration(milliseconds: 600));
      await _reveal(tester, find.text('Sprache'));
      expect(find.text('Sprache'), findsOneWidget);
      _expectRail104(tester, 'de, Fensterbreite $width');
      await _shot(tester, '101-de-${width.round()}');

      // Deutsch -> Englisch: Breite je Frame des Wechsels pruefen.
      await _reveal(tester, find.text('English'));
      await tester.tap(find.text('English'));
      final widths = <double>[];
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        widths.add(tester.getSize(rail).width);
      }
      await _reveal(tester, find.text('Language'));
      expect(find.text('Language'), findsOneWidget);
      expect(
        find.descendant(of: rail, matching: find.text('SETTINGS')),
        findsOneWidget,
      );
      expect(widths.toSet(), <double>{
        LinefmMetrics.railWidth,
      }, reason: 'Breite sprang beim Wechsel: $widths');
      _expectRail104(tester, 'en, Fensterbreite $width');
      await _shot(tester, '101-en-${width.round()}');

      // Und zurueck.
      await _reveal(tester, find.text('Deutsch'));
      await tester.tap(find.text('Deutsch'));
      await _pumpFor(tester, const Duration(milliseconds: 600));
      await _reveal(tester, find.text('Sprache'));
      expect(find.text('Sprache'), findsOneWidget);
      _expectRail104(tester, 'de nach Rueckwechsel, Breite $width');
      expect(tester.takeException(), isNull);
      await _disposeWorld(tester, world);
    }
  }, timeout: const Timeout(Duration(minutes: 4)));

  // ---------------------------------------------------------------- Custom title bar

  testWidgets('Titelleiste - Maximieren, Doppelklick, Minimieren, '
      'Schliessen in den Tray, Groesse setzen', (tester) async {
    final desktop = DesktopController.instance;
    expect(
      desktop.caption.style,
      CaptionStyle.buttons,
      reason: 'Systemleiste konnte nicht ausgeblendet werden',
    );
    // Ohne Tray-Symbol beendet Schliessen die App statt sie auszublenden:
    // dann wuerde der Test das eigene Fenster zerstoeren.
    expect(
      desktop.tray.isAvailable,
      isTrue,
      reason: 'Tray auf dem Runner nicht verfuegbar',
    );

    await _setWindowSize(tester, const Size(1000, 680));
    final world = _World(settings: _settings(AppLanguage.de));
    await _pumpWorld(tester, world);
    final l10n = AppLocalizations.of(tester.element(find.byType(PlayerScreen)));

    // Aufbau: eine Leiste, 40 dp hoch, drei Schaltflaechen.
    expect(find.byType(DesktopTitleBar), findsOneWidget);
    expect(
      tester.getSize(find.byType(DesktopTitleBar)).height,
      TitleBarMetrics.height,
    );
    expect(find.byType(CaptionButton), findsNWidgets(3));
    expect(await _wm.isMaximized(), isFalse);
    expect(await _wm.isVisible(), isTrue);
    await _shot(tester, '87-01-normal-1000x680');

    // Groesse setzen und zuruecksetzen.
    await _setWindowSize(tester, const Size(880, 600));
    await _shot(tester, '87-02-groesse-880x600');
    await _setWindowSize(tester, const Size(1000, 680));
    final normalSize = await _wm.getSize();

    // Maximieren per Knopf.
    await tester.tap(_caption(CaptionButtonKind.maximize));
    await _waitWindow(() async => _wm.isMaximized(), 'Fenster maximiert');
    await _pumpUntil(
      tester,
      () => _caption(CaptionButtonKind.restore).evaluate().isNotEmpty,
      'Knopf wechselt auf "${l10n.windowRestore}"',
    );
    await _pumpFor(tester, const Duration(milliseconds: 500));
    await _shot(tester, '87-03-maximiert-per-knopf');

    // Wiederherstellen per Knopf: gleiche Groesse wie vorher.
    await tester.tap(_caption(CaptionButtonKind.restore));
    await _waitWindow(
      () async => !await _wm.isMaximized(),
      'Fenster wiederhergestellt',
    );
    await _pumpUntil(
      tester,
      () => _caption(CaptionButtonKind.maximize).evaluate().isNotEmpty,
      'Knopf wechselt auf "${l10n.windowMaximize}"',
    );
    await _pumpFor(tester, const Duration(milliseconds: 500));
    _expectSizeClose(await _wm.getSize(), normalSize);
    await _shot(tester, '87-04-wiederhergestellt-per-knopf');

    // Doppelklick auf die Leiste maximiert und stellt wieder her.
    await _doubleTapTitleBar(tester);
    await _waitWindow(() async => _wm.isMaximized(), 'Doppelklick maximiert');
    await _pumpUntil(
      tester,
      () => _caption(CaptionButtonKind.restore).evaluate().isNotEmpty,
      'Knopf zeigt "${l10n.windowRestore}" nach Doppelklick',
    );
    await _pumpFor(tester, const Duration(milliseconds: 500));
    await _shot(tester, '87-05-maximiert-per-doppelklick');
    await _doubleTapTitleBar(tester);
    await _waitWindow(
      () async => !await _wm.isMaximized(),
      'Doppelklick stellt wieder her',
    );
    await _pumpUntil(
      tester,
      () => _caption(CaptionButtonKind.maximize).evaluate().isNotEmpty,
      'Knopf zeigt "${l10n.windowMaximize}" nach zweitem Doppelklick',
    );
    await _pumpFor(tester, const Duration(milliseconds: 500));
    _expectSizeClose(await _wm.getSize(), normalSize);
    await _shot(tester, '87-06-wiederhergestellt-per-doppelklick');

    // Minimieren. Waehrend das Fenster minimiert ist, gibt es keine
    // Frames: nur ueber window_manager warten.
    await tester.tap(_caption(CaptionButtonKind.minimize));
    await _waitWindow(() async => _wm.isMinimized(), 'Fenster minimiert');
    await _shot(tester, '87-07-minimiert', flutter: false);
    await desktop.showWindow();
    await _waitWindow(
      () async => !await _wm.isMinimized() && await _wm.isVisible(),
      'Fenster wieder da',
    );
    await _pumpFor(tester, const Duration(milliseconds: 600));
    await _shot(tester, '87-08-nach-minimieren');

    // Schliessen: das Fenster verschwindet, die App laeuft im Tray weiter.
    expect(await _wm.isPreventClose(), isTrue);
    await tester.tap(_caption(CaptionButtonKind.close));
    await _waitWindow(() async => !await _wm.isVisible(), 'Fenster im Tray');
    await _shot(tester, '87-09-geschlossen-im-tray', flutter: false);
    expect(
      desktop.tray.isAvailable,
      isTrue,
      reason: 'Tray-Symbol fehlt nach Schliessen',
    );
    // Wie "Fenster zeigen" im Tray-Menue.
    await desktop.showWindow();
    await _waitWindow(() async => _wm.isVisible(), 'Fenster wieder sichtbar');
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.byType(DesktopTitleBar), findsOneWidget);
    await _shot(tester, '87-10-aus-dem-tray-zurueck');

    expect(tester.takeException(), isNull);
    await _disposeWorld(tester, world);
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('Tastatur - Tab-Fokus und Kuerzel, Mini-Fenster und zurueck', (
    tester,
  ) async {
    final desktop = DesktopController.instance;
    await _setWindowSize(tester, const Size(1000, 680));
    final world = _World(settings: _settings(AppLanguage.de));
    await _pumpWorld(tester, world);

    // Tab bewegt den Fokus durch die Bedienelemente.
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(
      FocusManager.instance.primaryFocus,
      isNotNull,
      reason: 'Nach Tab hat kein Element den Fokus',
    );
    await _shot(tester, '60-01-tab-fokus');

    // Ziffer 2 startet den zweiten Sender (Ein-Zeichen-Kuerzel).
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await _pumpUntil(
      tester,
      () =>
          world.container.read(activeStationProvider).slug ==
          stationsCatalog[1].slug,
      'Sender 2 per Taste 2',
    );
    await _shot(tester, '60-02-taste-2-sender-2');

    // Mini-Fenster: 360 x 120, rahmenlos, standardmaessig im Vordergrund.
    await desktop.enterMini();
    await _waitWindow(() async {
      final size = await _wm.getSize();
      return (size.width - 360).abs() <= 2 && (size.height - 120).abs() <= 2;
    }, 'Mini-Fenster 360 x 120');
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(desktop.miniMode.value, isTrue);
    expect(await _wm.isAlwaysOnTop(), isTrue);
    await _shot(tester, '60-03-mini-fenster');

    await desktop.exitMini();
    await _waitWindow(() async {
      final size = await _wm.getSize();
      return size.width > 500 && size.height > 300;
    }, 'Normales Fenster nach Mini-Fenster');
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(desktop.miniMode.value, isFalse);
    expect(await _wm.isAlwaysOnTop(), isFalse);
    expect(find.byType(DesktopTitleBar), findsOneWidget);
    await _shot(tester, '60-04-zurueck-aus-mini-fenster');

    expect(tester.takeException(), isNull);
    await _disposeWorld(tester, world);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

// ------------------------------------------------------------------ Welt

String _old(Station s) => 'Alt ${s.slug}';
String _new(Station s) => 'Neu ${s.slug}';

AppSettings _settings(AppLanguage language) => AppSettings(
  autoplay: false,
  marquee: false,
  loadArtwork: false,
  language: language,
);

/// laut.fm-Fake: Antworten kommen sofort oder (gated) erst, wenn der Test sie
/// freigibt. Gleiche Form wie `_GatedApi` im Repository-Test.
class _GatedApi implements LautApi {
  final Map<String, Track?> current = <String, Track?>{};
  final Map<String, Completer<Object?>> pending =
      <String, Completer<Object?>>{};
  bool gated = false;

  Future<T> _call<T>(String key, T value) async {
    if (!gated) return value;
    final c = pending.putIfAbsent(key, Completer<Object?>.new);
    final result = await c.future;
    return result is T ? result : value;
  }

  void release(String key, Object? value) =>
      pending.remove(key)!.complete(value);

  @override
  Future<Track?> currentSong(String slug) =>
      _call('current:$slug', current[slug]);

  @override
  Future<List<Track>> lastSongs(String slug) =>
      _call('last:$slug', const <Track>[]);

  @override
  Future<int?> listeners(String slug) => _call('listeners:$slug', null);

  @override
  Future<List<ScheduleSlot>> schedule(String slug) async =>
      const <ScheduleSlot>[];

  @override
  Future<String?> streamUrl(String slug) async => null;
}

class _ConsentGiven extends TelemetryConsentNotifier {
  @override
  bool? build() => true;
}

/// App mit Live-Daten-Motor und Fake-API, ohne Audio.
class _World {
  _World({required AppSettings settings}) {
    final base = DateTime.now();
    clock = FakeClock(base);
    for (final s in stationsCatalog) {
      api.current[s.slug] = Track(
        artist: 'Kuenstler ${s.slug}',
        title: _old(s),
        startedAt: base,
        endsAt: base.add(const Duration(minutes: 3)),
      );
    }
    prefs = InMemoryPrefsStore();
    prefs.writeSettings(settings).ignore();
    prefs.setStorageConsent(value: true).ignore();
    container = ProviderContainer(
      overrides: <Override>[
        prefsProvider.overrideWithValue(prefs),
        playbackServiceProvider.overrideWithValue(playback),
        lautApiProvider.overrideWithValue(api),
        telemetryConsentProvider.overrideWith(_ConsentGiven.new),
        nowPlayingRepositoryProvider.overrideWith((ref) {
          final repo = LiveNowPlayingRepository(
            api: api,
            clock: clock,
            activeStation: ref.read(activeStationProvider),
            // Keine Zeitgeber waehrend des Tests: Abrufe loesen nur die
            // Senderwechsel aus.
            pollInterval: const Duration(hours: 1),
            maxEndsAtDelay: const Duration(hours: 1),
            unknownEndDelay: const Duration(hours: 1),
          );
          bindNowPlayingRepository(ref, repo);
          return repo;
        }),
      ],
    );
  }

  late final InMemoryPrefsStore prefs;
  final NoopPlaybackService playback = NoopPlaybackService();
  late final ProviderContainer container;

  final _GatedApi api = _GatedApi();
  late final FakeClock clock;
  final GlobalKey shotKey = GlobalKey();

  /// Neuer Titel eines Senders, beginnend zur aktuellen Uhrzeit des Fakes.
  Track next(Station s) => Track(
    artist: 'Kuenstler ${s.slug}',
    title: _new(s),
    startedAt: clock.now(),
    endsAt: clock.now().add(const Duration(minutes: 3)),
  );
}

_World? _current;

Future<void> _pumpWorld(WidgetTester tester, _World world) async {
  _current = world;
  loaderShownThisProcess = true;
  await tester.pumpWidget(
    RepaintBoundary(
      key: world.shotKey,
      child: UncontrolledProviderScope(
        container: world.container,
        child: const LinefmApp(),
      ),
    ),
  );
  await _pumpFor(tester, const Duration(milliseconds: 1500));
}

Future<void> _disposeWorld(WidgetTester tester, _World world) async {
  await tester.pumpWidget(const SizedBox.shrink());
  world.container.dispose();
  _current = null;
}

// ------------------------------------------------------------- Pruefungen

Finder _inPlayer(Finder f) =>
    find.descendant(of: find.byType(PlayerScreen), matching: f);

/// Player zeigt den Sender [s] und (wenn angegeben) [title]; keiner der
/// [forbidden]-Titel steht im Player.
void _expectPlayer(
  Station s, {
  String? title,
  List<String> forbidden = const <String>[],
}) {
  expect(
    _inPlayer(find.text(s.displayName.toUpperCase())),
    findsWidgets,
    reason: 'Sender ${s.displayName} fehlt im Player',
  );
  if (title != null) {
    expect(
      _inPlayer(find.text(title.toUpperCase())),
      findsWidgets,
      reason: 'Titel "$title" fehlt im Player',
    );
  }
  for (final t in forbidden) {
    expect(
      _inPlayer(find.text(t.toUpperCase())),
      findsNothing,
      reason: 'Titel "$t" darf im Player nicht stehen',
    );
  }
}

void _expectRail104(WidgetTester tester, String context) {
  final rail = find.byKey(const ValueKey<String>('shell-rail'));
  expect(
    tester.getSize(rail).width,
    LinefmMetrics.railWidth,
    reason: 'Rail-Box ($context)',
  );
  expect(
    tester.getSize(find.byType(NavigationRail)).width,
    LinefmMetrics.railWidth,
    reason: 'NavigationRail ($context)',
  );
}

void _expectSizeClose(Size actual, Size expected, {double tolerance = 2}) {
  expect(
    (actual.width - expected.width).abs() <= tolerance &&
        (actual.height - expected.height).abs() <= tolerance,
    isTrue,
    reason: 'Fenstergroesse $actual statt $expected',
  );
}

Finder _caption(CaptionButtonKind kind) => find.byWidgetPredicate(
  (w) => w is CaptionButton && w.kind == kind,
  description: 'CaptionButton(${kind.name})',
);

/// Scrollt die Einstellungen, bis [target] gebaut und sichtbar ist.
Future<void> _reveal(WidgetTester tester, Finder target) async {
  final scrollable = find
      .descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(target, 120, scrollable: scrollable);
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _tapStation(WidgetTester tester, Station s) async {
  final card = find.byWidgetPredicate(
    (w) => w is StationCard && w.station.slug == s.slug,
    description: 'Senderkarte ${s.slug}',
  );
  expect(card, findsOneWidget);
  // Mittig scrollen: am Rand liegt der Header ueber der Karte.
  await Scrollable.ensureVisible(tester.element(card), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(card);
}

Future<void> _doubleTapTitleBar(WidgetTester tester) async {
  final area = find.descendant(
    of: find.byType(DesktopTitleBar),
    matching: find.byType(DragToMoveArea),
  );
  expect(area, findsOneWidget);
  // Mitte der Zieh-Flaeche: leer, die Wortmarke steht links.
  final center = tester.getCenter(area);
  await tester.tapAt(center);
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tapAt(center);
  await tester.pump(const Duration(milliseconds: 100));
}

// ---------------------------------------------------------------- Warten

/// Echtzeit pumpen (Live-Binding: `pump(Dauer)` wartet wirklich).
Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
  String what, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      fail('Zeitueberschreitung beim Warten auf: $what');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Wartet auf einen Fensterzustand, ohne Frames zu brauchen (minimiert oder
/// ausgeblendet gibt es keine).
Future<void> _waitWindow(
  Future<bool> Function() condition,
  String what, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(end)) {
      fail('Zeitueberschreitung beim Warten auf: $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

/// Fenstergroesse setzen und warten, bis die App sie als Ansicht hat.
Future<void> _setWindowSize(WidgetTester tester, Size size) async {
  if (await _wm.isMaximized()) await _wm.unmaximize();
  await _wm.setSize(size);
  Size now = await _wm.getSize();
  final until = DateTime.now().add(const Duration(seconds: 5));
  while ((now.width - size.width).abs() > 2 ||
      (now.height - size.height).abs() > 2) {
    if (DateTime.now().isAfter(until)) {
      fail('Fenstergroesse $size nicht erreicht, aktuell $now');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    now = await _wm.getSize();
  }
  final view = tester.view;
  final end = DateTime.now().add(const Duration(seconds: 10));
  // Die Ansicht ist um den unsichtbaren Rahmen kleiner als das Fenster.
  while ((view.physicalSize.width / view.devicePixelRatio - size.width).abs() >
      40) {
    if (DateTime.now().isAfter(end)) {
      fail(
        'Ansicht ${view.physicalSize / view.devicePixelRatio} passt nicht '
        'zur Fenstergroesse $size',
      );
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 100));
}

// ---------------------------------------------------------------- Bilder

/// Bild der Flutter-Ansicht (`NN-name.png`) und, soweit moeglich, des
/// ganzen Bildschirms mit Fensterrahmen (`NN-name-bildschirm.png`).
Future<void> _shot(
  WidgetTester tester,
  String name, {
  bool flutter = true,
}) async {
  final id = '${(++_shotNumber).toString().padLeft(2, '0')}-$name';
  if (flutter) {
    await tester.pump(const Duration(milliseconds: 100));
    final context = _current?.shotKey.currentContext;
    expect(context, isNotNull, reason: 'Bildaufnahme: Ansicht fehlt');
    final boundary = context!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull);
    File('${_shotDir.path}${Platform.pathSeparator}$id.png')
        .writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  }
  await _desktopShot(
    '${_shotDir.path}${Platform.pathSeparator}$id-bildschirm.png',
  );
}

/// Bildschirmaufnahme mit Windows PowerShell; schlaegt sie fehl, wird das
/// nur gemeldet (die Flutter-Bilder bleiben der Beleg).
Future<void> _desktopShot(String path) async {
  try {
    final script = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}linefm_itest_shot.ps1',
    );
    script.writeAsStringSync(r'''
param([string]$Out)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$b = [System.Windows.Forms.SystemInformation]::VirtualScreen
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.Left, $b.Top, 0, 0, $bmp.Size)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
''');
    final result = await Process.run('powershell', <String>[
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      script.path,
      path,
    ]).timeout(const Duration(seconds: 30));
    if (result.exitCode != 0) {
      // ignore: avoid_print
      print(
        'Bildschirmaufnahme fehlgeschlagen (${result.exitCode}): '
        '${result.stderr}',
      );
    }
  } on Object catch (e) {
    // ignore: avoid_print
    print('Bildschirmaufnahme nicht moeglich: $e');
  }
}

const String _stationsJson =
    r'''{"hinweis": "Senderliste der App. Anleitung: docs/SENDER-VERWALTEN.md", "schemaVersion": 1, "sender": [{"kuerzel": "linefm", "name": "LineFM +MAIN", "farbe": "#4B4B7D", "logo": "https://cdn.linefm.de/images/icons/main.png", "logoDatei": "assets/images/stations/main.png"}, {"kuerzel": "linefmrap", "name": "LineFM +RAP", "farbe": "#FF0084", "logo": "https://cdn.linefm.de/images/icons/rap.png", "logoDatei": "assets/images/stations/rap.png"}, {"kuerzel": "linefmgaming", "name": "LineFM +GAMING", "farbe": "#4BBD71", "logo": "https://cdn.linefm.de/images/icons/gaming.png", "logoDatei": "assets/images/stations/gaming.png"}, {"kuerzel": "linefmlofi", "name": "LineFM +LOFI", "farbe": "#546E7A", "logo": "https://cdn.linefm.de/images/icons/lofi.png", "logoDatei": "assets/images/stations/lofi.png"}, {"kuerzel": "radio3fm", "name": "Radio3FM", "farbe": "#177D29", "logo": "https://cdn.linefm.de/images/icons/radio3fm.png", "logoDatei": "assets/images/stations/radio3fm.png"}, {"kuerzel": "fobfm", "name": "FobFM", "farbe": "#04FFF7", "logo": "https://cdn.linefm.de/images/icons/fobfm.png", "logoDatei": "assets/images/stations/fobfm.png"}]}''';
