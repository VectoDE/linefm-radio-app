import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/app.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/features/mini_player/mini_player.dart';
import 'package:linefm_radio/features/player/player_screen.dart';
import 'package:linefm_radio/features/settings/settings_screen.dart';
import 'package:linefm_radio/features/storage_notice/storage_notice.dart';
import 'package:material_ui/material_ui.dart';

import 'app_host.dart';

const _noAutoplay = AppSettings(autoplay: false);

void main() {
  group('Sprache', () {
    test('?lang= setzt die Sprache, sonst System', () {
      expect(localeFromQuery(Uri.parse('/?lang=en')), const Locale('en'));
      expect(localeFromQuery(Uri.parse('/?lang=de')), const Locale('de'));
      expect(localeFromQuery(Uri.parse('/?lang=fr')), isNull);
      expect(localeFromQuery(Uri.parse('/')), isNull);
    });

    test('Deutsch bleibt Deutsch, alles andere Englisch', () {
      expect(resolveAppLocale(const Locale('de', 'AT')), const Locale('de'));
      expect(resolveAppLocale(const Locale('fr')), const Locale('en'));
      expect(resolveAppLocale(null), const Locale('en'));
    });

    testWidgets('?lang=en schaltet die Oberflaeche auf Englisch', (
      tester,
    ) async {
      useSize(tester, 390, 844);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host, uri: Uri.parse('https://x/?lang=en'));
      expect(find.text('All stations'.toUpperCase()), findsOneWidget);
      expect(find.text('STATIONS'), findsOneWidget);
      await disposeApp(tester, host);
    });
  });

  group('Handy', () {
    testWidgets('Header, Navigation, Mini-Player und Speicher-Hinweis', (
      tester,
    ) async {
      useSize(tester, 390, 844);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);

      expect(find.text('LINEFM'), findsOneWidget);
      expect(find.byTooltip('Einstellungen'), findsOneWidget);
      for (final label in <String>['STATIONEN', 'PLAYER', 'VERLAUF']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.byType(StorageNotice), findsOneWidget);
      expect(find.text('ALLE STATIONEN'), findsOneWidget);
      expect(host.sink.events, contains('screen:stations'));
      await disposeApp(tester, host);
    });

    testWidgets('Sender waehlen: Player zeigt Titel aus der Fake-API', (
      tester,
    ) async {
      useSize(tester, 390, 844);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);

      await tester.tap(find.text('LINEFM +RAP'));
      await settleApp(tester);

      expect(host.container.read(navigationProvider), AppScreen.player);
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(find.text('Erfolg ist kein Glück'), findsWidgets);
      expect(find.byType(MiniPlayer), findsNothing);
      expect(host.playback.state.isPlaying, isTrue);
      expect(host.active.slug, 'linefmrap');
      // Genau ein play-Ereignis (keine Doppelmeldung aus Liste + Controller).
      expect(host.sink.names.where((n) => n == 'play'), hasLength(1));
      expect(host.sink.events, contains('screen:player'));
      await disposeApp(tester, host);
    });

    testWidgets('Navigation und Zurueck fuehren zu den Stationen', (
      tester,
    ) async {
      useSize(tester, 390, 844);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);

      await tester.tap(find.text('VERLAUF'));
      await settleApp(tester);
      expect(find.text('ZULETZT GESPIELT'), findsOneWidget);
      // Verlauf meldet sich selbst, die Shell nicht doppelt.
      expect(
        host.sink.events.where((e) => e == 'screen:history'),
        hasLength(1),
      );

      await tester.tap(find.byTooltip('Einstellungen'));
      await settleApp(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Favoriten').first);
      await settleApp(tester);
      expect(host.container.read(navigationProvider), AppScreen.favorites);

      final handled = await tester.binding.handlePopRoute();
      await settleApp(tester);
      expect(handled, isTrue);
      expect(host.container.read(navigationProvider), AppScreen.stations);
      await disposeApp(tester, host);
    });

    testWidgets('Offline-Leiste, wenn laut.fm nicht erreichbar ist', (
      tester,
    ) async {
      useSize(tester, 390, 844);
      final host = AppHost(
        settings: _noAutoplay,
        repository: TestRepository(online: false),
      );
      await pumpApp(tester, host);
      expect(
        find.text('Keine Verbindung. LINEFM versucht es weiter.'),
        findsOneWidget,
      );
      await disposeApp(tester, host);
    });

    testWidgets('Autoplay startet die letzte Station', (tester) async {
      useSize(tester, 390, 844);
      final host = AppHost();
      await host.prefs.writeLastStation('linefmlofi');
      await pumpApp(tester, host);
      expect(host.playback.state.isPlaying, isTrue);
      expect(host.playback.state.station?.slug, 'linefmlofi');
      await disposeApp(tester, host);
    });

    testWidgets('Tastenkuerzel: Ziffer startet Sender, Leertaste stoppt', (
      tester,
    ) async {
      useSize(tester, 390, 844);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await settleApp(tester);
      expect(host.active, stationsCatalog[2]);
      expect(host.playback.state.isPlaying, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await settleApp(tester);
      expect(host.playback.state.isPlaying, isFalse);
      await disposeApp(tester, host);
    });
  });

  group('Tablet/Desktop', () {
    testWidgets('zweispaltig: Rail, Liste und eingebetteter Player', (
      tester,
    ) async {
      useSize(tester, 1280, 800);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(find.text('ALLE STATIONEN'), findsOneWidget);
      expect(find.byType(MiniPlayer), findsNothing);
      expect(find.text('PLAYER'), findsNothing);

      // Sender antippen: kein Wechsel weg von der Liste.
      await tester.tap(find.text('LINEFM +GAMING'));
      await settleApp(tester);
      expect(host.container.read(navigationProvider), AppScreen.stations);
      expect(host.active.slug, 'linefmgaming');
      await disposeApp(tester, host);
    });

    testWidgets('Wechsel der Fensterbreite wechselt das Layout', (
      tester,
    ) async {
      useSize(tester, 1280, 800);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);
      expect(find.byType(NavigationRail), findsOneWidget);

      tester.view.physicalSize = const Size(700, 900);
      await settleApp(tester);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('VERLAUF'), findsOneWidget);
      await disposeApp(tester, host);
    });
  });
}
