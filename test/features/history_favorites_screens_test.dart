import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/features/favorites/favorites_screen.dart';
import 'package:linefm_radio/features/history/history_format.dart';
import 'package:linefm_radio/features/history/history_screen.dart';
import 'package:linefm_radio/features/history/icon_action.dart';
import 'package:material_ui/material_ui.dart';

import 'history_favorites_helpers.dart';

void main() {
  group('formatClock', () {
    const en = DefaultMaterialLocalizations();
    test('24-Stunden-Einstellung: HH:mm mit fuehrender Null', () {
      String f(DateTime t) => formatClock(t, en, alwaysUse24HourFormat: true);
      expect(f(DateTime(2026, 11, 18, 8, 7)), '08:07');
      expect(f(DateTime(2026, 11, 18, 21, 40)), '21:40');
      expect(f(DateTime(2026, 11, 18)), '00:00');
    });
    test('Englisch ohne 24-Stunden-Einstellung: 12 Stunden', () {
      expect(formatClock(DateTime(2026, 11, 18, 21, 40), en), '9:40 PM');
    });
  });

  group('HistoryScreen', () {
    testWidgets('zeigt LIVE oben und Uhrzeit HH:mm je Eintrag', (tester) async {
      final ctx = await pumpScreen(tester, const HistoryScreen());
      expect(find.text('ZULETZT GESPIELT'), findsOneWidget);
      expect(find.text("I Was Lovin' You"), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('21:02'), findsOneWidget);
      expect(find.text('08:07'), findsOneWidget);
      expect(ctx.telemetry.screens, <String>['history']);
    });

    testWidgets('Leerzustand', (tester) async {
      await pumpScreen(
        tester,
        const HistoryScreen(),
        history: <HistoryEntry>[],
      );
      expect(find.text('Noch keine Titel im Verlauf.'), findsOneWidget);
    });

    testWidgets('Herz merkt Song, meldet Ereignis und nimmt ihn zurueck', (
      tester,
    ) async {
      final ctx = await pumpScreen(tester, const HistoryScreen());
      final add = find.byType(IconAction);
      expect(add, findsNWidgets(3));

      await tester.tap(add.at(1));
      await settle(tester);
      final favorites = ctx.container.read(favoritesProvider);
      expect(favorites, hasLength(1));
      expect(favorites.single.title, 'Waterfall');
      expect(favorites.single.stationSlug, stationsCatalog.first.slug);
      expect(favorites.single.savedAt, t);
      expect(ctx.telemetry.events, <String>['favorite_add']);
      expect(
        tester.widget<IconAction>(add.at(1)).label,
        'Aus Favoriten entfernen',
      );

      await tester.tap(add.at(1));
      await settle(tester);
      expect(ctx.container.read(favoritesProvider), isEmpty);
      expect(ctx.telemetry.events, <String>['favorite_add', 'favorite_remove']);
    });

    testWidgets('Screenreader-Label fasst Zeile zusammen', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, const HistoryScreen());
      expect(
        find.bySemanticsLabel('Waterfall, Michael Calfan & Ofenbach, 21:02'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel("I Was Lovin' You, James Hype, LIVE"),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('Screenreader-Tap auf "Song merken" schaltet um', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final ctx = await pumpScreen(tester, const HistoryScreen());
      final heart = find.semantics.byLabel('Song merken').first;
      tester.semantics.tap(heart);
      await settle(tester);
      expect(ctx.container.read(favoritesProvider), hasLength(1));
      expect(ctx.telemetry.events, <String>['favorite_add']);

      tester.semantics.tap(
        find.semantics.byLabel('Aus Favoriten entfernen').first,
      );
      await settle(tester);
      expect(ctx.container.read(favoritesProvider), isEmpty);
      handle.dispose();
    });

    testWidgets('Pull-to-refresh laedt nach', (tester) async {
      final ctx = await pumpScreen(tester, const HistoryScreen());
      await tester.fling(
        find.text("I Was Lovin' You"),
        const Offset(0, 400),
        1000,
      );
      await settle(tester);
      expect(ctx.repo.refreshes, 1);
    });

    testWidgets('Textskalierung 200 % ohne Layoutfehler', (tester) async {
      await pumpScreen(tester, const HistoryScreen(), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('21:02'), findsOneWidget);
    });

    testWidgets('ohne Animationen erscheinen Zeilen sofort', (tester) async {
      await pumpScreen(tester, const HistoryScreen(), disableAnimations: true);
      expect(find.text('Waterfall'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('FavoritesScreen', () {
    testWidgets('Leerzustand im Wortlaut, kein Export-Knopf', (tester) async {
      final ctx = await pumpScreen(tester, const FavoritesScreen());
      expect(find.text('Noch keine Favoriten gespeichert.'), findsOneWidget);
      expect(action('Favoriten exportieren'), findsNothing);
      expect(ctx.telemetry.screens, <String>['favorites']);
    });

    testWidgets('Leerzustand fuehrt mit "Sender entdecken" zu den Sendern', (
      tester,
    ) async {
      final ctx = await pumpScreen(tester, const FavoritesScreen());
      final action = find.widgetWithText(OutlinedButton, 'Sender entdecken');
      expect(action, findsOneWidget);
      await tester.tap(action);
      await settle(tester);
      expect(ctx.container.read(navigationProvider), AppScreen.stations);
    });

    testWidgets('Liste, Entfernen mit Papierkorb, Ereignis', (tester) async {
      final ctx = await pumpScreen(
        tester,
        const FavoritesScreen(),
        favorites: <Favorite>[
          fav('Waterfall', 'Michael Calfan'),
          fav('Last Night', 'Bruno Mars', station: 'linefmrap'),
        ],
      );
      expect(find.text('Waterfall'), findsOneWidget);
      expect(find.text('Last Night'), findsOneWidget);

      await tester.tap(action('Waterfall aus Favoriten entfernen'));
      await settle(tester);
      expect(find.text('Waterfall'), findsNothing);
      expect(
        ctx.container.read(favoritesProvider).map((f) => f.title),
        <String>['Last Night'],
      );
      expect(ctx.prefs.readFavorites().map((f) => f.title), <String>[
        'Last Night',
      ]);
      expect(ctx.telemetry.events, <String>['favorite_remove']);

      await tester.tap(action('Last Night aus Favoriten entfernen'));
      await settle(tester);
      expect(find.text('Noch keine Favoriten gespeichert.'), findsOneWidget);
    });

    testWidgets('Export: Auswahl CSV ruft Share-Service und meldet Ereignis', (
      tester,
    ) async {
      final ctx = await pumpScreen(
        tester,
        const FavoritesScreen(),
        favorites: <Favorite>[fav('Waterfall', 'Michael Calfan')],
      );
      await tester.tap(action('Favoriten exportieren'));
      await settle(tester);
      expect(find.text('Als CSV-Datei'), findsOneWidget);
      expect(find.text('Als Text'), findsOneWidget);

      await tester.tap(find.text('Als CSV-Datei'));
      await settle(tester);
      expect(ctx.share.exports, hasLength(1));
      expect(ctx.share.exports.single.$2, ExportFormat.csv);
      expect(ctx.share.exports.single.$1.single.title, 'Waterfall');
      expect(ctx.telemetry.events, <String>['export_favorites{format: csv}']);
    });

    testWidgets('Export schlaegt fehl: Hinweis, kein Ereignis', (tester) async {
      final ctx = await pumpScreen(
        tester,
        const FavoritesScreen(),
        favorites: <Favorite>[fav('Waterfall', 'Michael Calfan')],
        shareFails: true,
      );
      await tester.tap(action('Favoriten exportieren'));
      await settle(tester);
      await tester.tap(find.text('Als Text'));
      await settle(tester);
      expect(
        find.text('Der Export hat nicht geklappt. Versuche es noch einmal.'),
        findsOneWidget,
      );
      expect(ctx.telemetry.events, isEmpty);
    });

    testWidgets('Export-Sheet abbrechen tut nichts', (tester) async {
      final ctx = await pumpScreen(
        tester,
        const FavoritesScreen(),
        favorites: <Favorite>[fav('Waterfall', 'Michael Calfan')],
      );
      await tester.tap(action('Favoriten exportieren'));
      await settle(tester);
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
      expect(ctx.share.exports, isEmpty);
    });
  });
}
