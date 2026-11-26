import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/favorites/favorites_header_button.dart';
import 'package:linefm_radio/features/favorites/favorites_screen.dart';
import 'package:linefm_radio/features/history/history_format.dart';
import 'package:linefm_radio/features/history/history_screen.dart';
import 'package:linefm_radio/features/history/icon_action.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/share/share_service.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_doubles.dart';

class _Repo extends FakeNowPlayingRepository {
  _Repo(this.entries);

  final List<HistoryEntry> entries;
  int refreshes = 0;

  @override
  Stream<List<HistoryEntry>> watchHistory(Station station) =>
      Stream<List<HistoryEntry>>.value(entries);

  @override
  Future<void> refresh() async => refreshes++;
}

class _Telemetry extends TelemetryHub {
  _Telemetry() : super(config: AppConfig.fromEnvironment());

  final List<String> events = <String>[];
  final List<String> screens = <String>[];

  @override
  Future<void> event(
    String name, [
    Map<String, Object> props = const <String, Object>{},
  ]) async => events.add(props.isEmpty ? name : '$name$props');

  @override
  Future<void> screen(String name) async => screens.add(name);
}

class _Share extends NoopShareService {
  _Share({this.fail = false});

  final bool fail;
  final List<(List<Favorite>, ExportFormat)> exports =
      <(List<Favorite>, ExportFormat)>[];

  @override
  Future<void> exportFavorites(
    List<Favorite> favorites,
    ExportFormat format,
  ) async {
    if (fail) throw StateError('kaputt');
    exports.add((favorites, format));
  }
}

/// Lauftext laeuft endlos, deshalb kein `pumpAndSettle`: erst Frame, dann 1 s
/// (Einblenden, Sheets und Entfernen dauern hoechstens 0,5 s).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Finder _action(String label) => find.byWidgetPredicate(
  (w) => w is IconAction && w.label == label,
  description: 'IconAction "$label"',
);

final DateTime _t = DateTime(2026, 11, 18, 21, 5);

List<HistoryEntry> _entries() => <HistoryEntry>[
  const HistoryEntry(
    track: Track(artist: 'James Hype', title: "I Was Lovin' You"),
    isLive: true,
  ),
  HistoryEntry(
    track: Track(
      artist: 'Michael Calfan & Ofenbach',
      title: 'Waterfall',
      startedAt: DateTime(2026, 11, 18, 21, 2),
    ),
  ),
  HistoryEntry(
    track: Track(
      artist: 'Bruno Mars',
      title: 'Last Night',
      startedAt: DateTime(2026, 11, 18, 8, 7),
    ),
  ),
];

Favorite _fav(String title, String artist, {String station = 'linefm'}) =>
    Favorite(
      key: '$station:${artist.toLowerCase()}:${title.toLowerCase()}',
      stationSlug: station,
      title: title,
      artist: artist,
      savedAt: _t,
    );

Future<
  ({
    ProviderContainer container,
    _Telemetry telemetry,
    _Share share,
    _Repo repo,
    InMemoryPrefsStore prefs,
  })
>
_pump(
  WidgetTester tester,
  Widget screen, {
  List<HistoryEntry>? history,
  List<Favorite> favorites = const <Favorite>[],
  double width = 390,
  double height = 844,
  bool shareFails = false,
  bool disableAnimations = false,
  double textScale = 1,
}) async {
  // material_ui und Cupertino-Delegate kollidieren (P01-Bericht 2); die reine
  // Debug-Warnung zur Sprache de wuerde sonst jeden Test fehlschlagen lassen.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('localization delegates')) return;
    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final prefs = InMemoryPrefsStore();
  await prefs.writeFavorites(favorites);
  await prefs.writeSettings(const AppSettings(marquee: false));
  final telemetry = _Telemetry();
  final shareService = _Share(fail: shareFails);
  final repo = _Repo(history ?? _entries());
  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      telemetryProvider.overrideWithValue(telemetry),
      shareServiceProvider.overrideWithValue(shareService),
      nowPlayingRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(FakeClock(_t)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildLinefmTheme(Brightness.dark),
        locale: const Locale('de'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: app!,
        ),
        home: Scaffold(body: screen),
      ),
    ),
  );
  await _settle(tester);
  return (
    container: container,
    telemetry: telemetry,
    share: shareService,
    repo: repo,
    prefs: prefs,
  );
}

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
      final ctx = await _pump(tester, const HistoryScreen());
      expect(find.text('ZULETZT GESPIELT'), findsOneWidget);
      expect(find.text("I Was Lovin' You"), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('21:02'), findsOneWidget);
      expect(find.text('08:07'), findsOneWidget);
      expect(ctx.telemetry.screens, <String>['history']);
    });

    testWidgets('Leerzustand', (tester) async {
      await _pump(tester, const HistoryScreen(), history: <HistoryEntry>[]);
      expect(find.text('Noch keine Titel im Verlauf.'), findsOneWidget);
    });

    testWidgets('Herz merkt Song, meldet Ereignis und nimmt ihn zurueck', (
      tester,
    ) async {
      final ctx = await _pump(tester, const HistoryScreen());
      final add = find.byType(IconAction);
      expect(add, findsNWidgets(3));

      await tester.tap(add.at(1));
      await _settle(tester);
      final favorites = ctx.container.read(favoritesProvider);
      expect(favorites, hasLength(1));
      expect(favorites.single.title, 'Waterfall');
      expect(favorites.single.stationSlug, stationsCatalog.first.slug);
      expect(favorites.single.savedAt, _t);
      expect(ctx.telemetry.events, <String>['favorite_add']);
      expect(
        tester.widget<IconAction>(add.at(1)).label,
        'Aus Favoriten entfernen',
      );

      await tester.tap(add.at(1));
      await _settle(tester);
      expect(ctx.container.read(favoritesProvider), isEmpty);
      expect(ctx.telemetry.events, <String>['favorite_add', 'favorite_remove']);
    });

    testWidgets('Screenreader-Label fasst Zeile zusammen', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const HistoryScreen());
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
      final ctx = await _pump(tester, const HistoryScreen());
      final heart = find.semantics.byLabel('Song merken').first;
      tester.semantics.tap(heart);
      await _settle(tester);
      expect(ctx.container.read(favoritesProvider), hasLength(1));
      expect(ctx.telemetry.events, <String>['favorite_add']);

      tester.semantics.tap(
        find.semantics.byLabel('Aus Favoriten entfernen').first,
      );
      await _settle(tester);
      expect(ctx.container.read(favoritesProvider), isEmpty);
      handle.dispose();
    });

    testWidgets('Pull-to-refresh laedt nach', (tester) async {
      final ctx = await _pump(tester, const HistoryScreen());
      await tester.fling(
        find.text("I Was Lovin' You"),
        const Offset(0, 400),
        1000,
      );
      await _settle(tester);
      expect(ctx.repo.refreshes, 1);
    });

    testWidgets('Textskalierung 200 % ohne Layoutfehler', (tester) async {
      await _pump(tester, const HistoryScreen(), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('21:02'), findsOneWidget);
    });

    testWidgets('ohne Animationen erscheinen Zeilen sofort', (tester) async {
      await _pump(tester, const HistoryScreen(), disableAnimations: true);
      expect(find.text('Waterfall'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('FavoritesScreen', () {
    testWidgets('Leerzustand im Wortlaut, kein Export-Knopf', (tester) async {
      final ctx = await _pump(tester, const FavoritesScreen());
      expect(find.text('Noch keine Favoriten gespeichert.'), findsOneWidget);
      expect(_action('Favoriten exportieren'), findsNothing);
      expect(ctx.telemetry.screens, <String>['favorites']);
    });

    testWidgets('Liste, Entfernen mit Papierkorb, Ereignis', (tester) async {
      final ctx = await _pump(
        tester,
        const FavoritesScreen(),
        favorites: <Favorite>[
          _fav('Waterfall', 'Michael Calfan'),
          _fav('Last Night', 'Bruno Mars', station: 'linefmrap'),
        ],
      );
      expect(find.text('Waterfall'), findsOneWidget);
      expect(find.text('Last Night'), findsOneWidget);

      await tester.tap(_action('Waterfall aus Favoriten entfernen'));
      await _settle(tester);
      expect(find.text('Waterfall'), findsNothing);
      expect(
        ctx.container.read(favoritesProvider).map((f) => f.title),
        <String>['Last Night'],
      );
      expect(ctx.prefs.readFavorites().map((f) => f.title), <String>[
        'Last Night',
      ]);
      expect(ctx.telemetry.events, <String>['favorite_remove']);

      await tester.tap(_action('Last Night aus Favoriten entfernen'));
      await _settle(tester);
      expect(find.text('Noch keine Favoriten gespeichert.'), findsOneWidget);
    });

    testWidgets('Export: Auswahl CSV ruft Share-Service und meldet Ereignis', (
      tester,
    ) async {
      final ctx = await _pump(
        tester,
        const FavoritesScreen(),
        favorites: <Favorite>[_fav('Waterfall', 'Michael Calfan')],
      );
      await tester.tap(_action('Favoriten exportieren'));
      await _settle(tester);
      expect(find.text('Als CSV-Datei'), findsOneWidget);
      expect(find.text('Als Text'), findsOneWidget);

      await tester.tap(find.text('Als CSV-Datei'));
      await _settle(tester);
      expect(ctx.share.exports, hasLength(1));
      expect(ctx.share.exports.single.$2, ExportFormat.csv);
      expect(ctx.share.exports.single.$1.single.title, 'Waterfall');
      expect(ctx.telemetry.events, <String>['export_favorites{format: csv}']);
    });

    testWidgets('Export schlaegt fehl: Hinweis, kein Ereignis', (tester) async {
      final ctx = await _pump(
        tester,
        const FavoritesScreen(),
        favorites: <Favorite>[_fav('Waterfall', 'Michael Calfan')],
        shareFails: true,
      );
      await tester.tap(_action('Favoriten exportieren'));
      await _settle(tester);
      await tester.tap(find.text('Als Text'));
      await _settle(tester);
      expect(
        find.text('Der Export hat nicht geklappt. Versuche es noch einmal.'),
        findsOneWidget,
      );
      expect(ctx.telemetry.events, isEmpty);
    });

    testWidgets('Export-Sheet abbrechen tut nichts', (tester) async {
      final ctx = await _pump(
        tester,
        const FavoritesScreen(),
        favorites: <Favorite>[_fav('Waterfall', 'Michael Calfan')],
      );
      await tester.tap(_action('Favoriten exportieren'));
      await _settle(tester);
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);
      expect(ctx.share.exports, isEmpty);
    });
  });

  group('FavoritesHeaderButton', () {
    testWidgets('Badge zeigt Anzahl, Semantik mit Zaehler, Tippen navigiert', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final ctx = await _pump(
        tester,
        const Align(
          alignment: Alignment.topRight,
          child: FavoritesHeaderButton(),
        ),
        favorites: <Favorite>[_fav('A', 'x'), _fav('B', 'x'), _fav('C', 'x')],
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.bySemanticsLabel('Favoriten, 3 Songs'), findsOneWidget);

      await tester.tap(find.byType(FavoritesHeaderButton));
      await tester.pump();
      expect(ctx.container.read(navigationProvider), AppScreen.favorites);

      ctx.container.read(favoritesProvider.notifier).remove('linefm:x:a');
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('ohne Favoriten kein Badge, ab 100 "99+"', (tester) async {
      final ctx = await _pump(
        tester,
        const Align(
          alignment: Alignment.topRight,
          child: FavoritesHeaderButton(),
        ),
      );
      expect(find.byType(Text), findsNothing);

      final many = <Favorite>[for (var i = 0; i < 120; i++) _fav('T$i', 'a')];
      ctx.container.read(prefsProvider).writeFavorites(many).ignore();
      ctx.container.invalidate(favoritesProvider);
      await tester.pump();
      expect(find.text('99+'), findsOneWidget);
    });
  });
}
