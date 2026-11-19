import 'package:flutter/semantics.dart';
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
import 'package:linefm_radio/ui/widgets/quiet_tooltip.dart';
import 'package:material_ui/material_ui.dart';

import 'app_host.dart';

const _noAutoplay = AppSettings(autoplay: false);

/// Knopf mit [QuietTooltip] (der Material-Finder `byTooltip` kennt nur
/// Tooltips mit Semantik).
Finder _byQuietTooltip(String message) =>
    find.byWidgetPredicate((w) => w is QuietTooltip && w.message == message);

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
      expect(_byQuietTooltip('Einstellungen'), findsOneWidget);
      for (final label in <String>['SENDER', 'PLAYER', 'VERLAUF']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.byType(StorageNotice), findsOneWidget);
      expect(find.text('ALLE SENDER'), findsOneWidget);
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

      await tester.tap(_byQuietTooltip('Einstellungen'));
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

    testWidgets('Einstellungen-Knopf: Rolle, Label einmal, Semantik-Tap (A5)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useSize(tester, 390, 844);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);

      // Genau ein Knoten mit dem Label (Blase ohne eigenen Knoten).
      expect(find.semantics.byLabel('Einstellungen'), findsOneWidget);
      final data = tester
          .getSemantics(find.bySemanticsLabel('Einstellungen'))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      tester.semantics.tap(find.semantics.byLabel('Einstellungen'));
      await settleApp(tester);
      expect(host.container.read(navigationProvider), AppScreen.settings);
      await disposeApp(tester, host);
      handle.dispose();
    });

    testWidgets('Vorhersagbares Zurueck (Android) fuehrt wie Zurueck (L3-03)', (
      tester,
    ) async {
      useSize(tester, 390, 844);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);

      Future<void> gesture(String method, [Object? args]) async {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          SystemChannels.backGesture.name,
          SystemChannels.backGesture.codec.encodeMethodCall(
            MethodCall(method, args),
          ),
          (_) {},
        );
        await settleApp(tester);
      }

      await tester.tap(find.text('VERLAUF'));
      await settleApp(tester);
      expect(host.container.read(navigationProvider), AppScreen.history);

      // Wie OnBackInvokedCallback mit enableOnBackInvokedCallback="true".
      await gesture('startBackGesture', <String, Object?>{
        'touchOffset': <double>[5, 400],
        'progress': 0.0,
        'swipeEdge': 0,
      });
      await gesture('updateBackGestureProgress', <String, Object?>{
        'touchOffset': <double>[120, 400],
        'progress': 0.6,
        'swipeEdge': 0,
      });
      await gesture('commitBackGesture');
      expect(host.container.read(navigationProvider), AppScreen.stations);

      // Abgebrochene Geste aendert nichts.
      await tester.tap(find.text('VERLAUF'));
      await settleApp(tester);
      await gesture('startBackGesture', <String, Object?>{
        'touchOffset': <double>[5, 400],
        'progress': 0.0,
        'swipeEdge': 0,
      });
      await gesture('cancelBackGesture');
      expect(host.container.read(navigationProvider), AppScreen.history);
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

  group('Tastatur-Reihenfolge (NEU-1)', () {
    testWidgets('Kompakt: Header, Inhalt, Hinweise, Mini-Player, Navigation', (
      tester,
    ) async {
      useSize(tester, 412, 860);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);

      final forward = await _tabRegions(tester, LogicalKeyboardKey.tab, 60);
      // Ein voller Durchlauf: jeder Bereich kommt vor, keiner kehrt nach
      // einem spaeteren Bereich zurueck (keine Falle im unteren Stapel).
      final firstPass = _untilWrap(forward);
      expect(firstPass.toSet(), containsAll(<int>[1, 2, 4, 5]));
      expect(_isSorted(firstPass), isTrue, reason: '$firstPass');
      expect(firstPass.last, 5);
      // Danach verlaesst Tab die Bereiche (Shell selbst) oder beginnt
      // wieder beim Header.
      expect(forward[firstPass.length], anyOf(0, 1));

      final backward = await _tabRegions(
        tester,
        LogicalKeyboardKey.tab,
        40,
        shift: true,
      );
      final backPass = _untilWrap(backward, reverse: true);
      expect(
        _isSorted(backPass.reversed.toList()),
        isTrue,
        reason: '$backPass',
      );
      await disposeApp(tester, host);
    });

    testWidgets('Kompakt: Favoriten und Einstellungen per Tab erreichbar', (
      tester,
    ) async {
      useSize(tester, 412, 860);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);

      final tooltips = <String>{};
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final context = FocusManager.instance.primaryFocus?.context;
        final tooltip = context?.findAncestorWidgetOfExactType<QuietTooltip>();
        if (tooltip != null) tooltips.add(tooltip.message);
      }
      expect(tooltips, contains('Einstellungen'));
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
      expect(find.text('ALLE SENDER'), findsOneWidget);
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

/// Drueckt [count] mal (Shift+)Tab und liefert je Schritt den Shell-Bereich
/// des fokussierten Elements (1 Header ... 5 Navigation, 0 ausserhalb).
Future<List<int>> _tabRegions(
  WidgetTester tester,
  LogicalKeyboardKey key,
  int count, {
  bool shift = false,
}) async {
  final regions = <int>[];
  for (var i = 0; i < count; i++) {
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump(const Duration(milliseconds: 50));
    regions.add(_regionOf(FocusManager.instance.primaryFocus?.context));
  }
  return regions;
}

/// Aeusserste [FocusTraversalOrder] ueber [context] = Bereich der Shell.
int _regionOf(BuildContext? context) {
  if (context == null) return 0;
  var region = 0;
  context.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is FocusTraversalOrder) {
      final order = widget.order;
      if (order is NumericFocusOrder) region = order.order.toInt();
    }
    return true;
  });
  return region;
}

/// Erster Durchlauf bis zum Umbruch (Bereich faellt bzw. steigt wieder).
List<int> _untilWrap(List<int> regions, {bool reverse = false}) {
  final out = <int>[];
  for (final r in regions) {
    if (out.isNotEmpty && (reverse ? r > out.last : r < out.last)) break;
    out.add(r);
  }
  return out;
}

bool _isSorted(List<int> values) {
  for (var i = 1; i < values.length; i++) {
    if (values[i] < values[i - 1]) return false;
  }
  return true;
}
