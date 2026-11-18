// Visueller Abgleich gegen die Web-App (Referenz: Screenshots in `_input/`,
// Handy 390 dp, Tablet 800 dp). Aktualisieren mit
// `flutter test --update-goldens test/features/history_favorites_golden_test.dart`.
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/data/live/now_playing_repository.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/favorites/favorites_header_button.dart';
import 'package:linefm_radio/features/favorites/favorites_screen.dart';
import 'package:linefm_radio/features/history/history_screen.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

class _Repo extends FakeNowPlayingRepository {
  @override
  Stream<List<HistoryEntry>> watchHistory(Station station) =>
      Stream<List<HistoryEntry>>.value(_history);
}

final List<HistoryEntry> _history = <HistoryEntry>[
  const HistoryEntry(
    track: Track(artist: 'James Hype', title: "I Was Lovin' You"),
    isLive: true,
  ),
  _e('Waterfall', 'Michael Calfan & Ofenbach', 21, 2),
  _e('Last Night', 'Bruno Mars', 20, 58),
  _e('CAN\'T STOP THE FEELING!', 'Justin Timberlake', 20, 54),
  _e('My Head & My Heart', 'Ava Max', 20, 51),
  _e('Smooth My Heart', 'Anne-Marie & Years & Years', 20, 47),
];

HistoryEntry _e(String title, String artist, int h, int m) => HistoryEntry(
  track: Track(
    artist: artist,
    title: title,
    startedAt: DateTime(2026, 11, 18, h, m),
  ),
);

Favorite _f(String title, String artist, String slug) => Favorite(
  key: '$slug:${artist.toLowerCase()}:${title.toLowerCase()}',
  stationSlug: slug,
  title: title,
  artist: artist,
  savedAt: DateTime(2026, 11, 18, 20, 0),
);

Future<void> _show(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  List<Favorite> favorites = const <Favorite>[],
}) async {
  // material_ui und Cupertino-Delegate kollidieren (P01-Bericht 2); die reine
  // Debug-Warnung zur Sprache de wuerde sonst jeden Test fehlschlagen lassen.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('localization delegates')) return;
    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final prefs = InMemoryPrefsStore();
  await prefs.writeFavorites(favorites);
  // Lauftext aus: statische, reproduzierbare Darstellung.
  await prefs.writeSettings(const AppSettings(marquee: false));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        nowPlayingRepositoryProvider.overrideWithValue(_Repo()),
        clockProvider.overrideWithValue(FakeClock(DateTime(2026, 11, 18))),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLinefmTheme(Brightness.dark),
        locale: const Locale('de'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SafeArea(
            child: Column(
              children: <Widget>[
                const Align(
                  alignment: Alignment.centerRight,
                  child: FavoritesHeaderButton(),
                ),
                Expanded(child: screen),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// `flutter test` zeichnet sonst Platzhalterbloecke: Schriften und Icons fuer
/// die Goldens selbst laden.
Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await load('Poppins', <String>[
    'assets/fonts/Poppins-Regular.ttf',
    'assets/fonts/Poppins-SemiBold.ttf',
  ]);
  await load('Syncopate', <String>['assets/fonts/Syncopate-Bold.ttf']);
  const fa = 'packages/font_awesome_flutter';
  await load('$fa/FontAwesomeSolid', <String>[
    '$fa/lib/fonts/Font-Awesome-7-Free-Solid-900.otf',
  ]);
  await load('$fa/FontAwesomeRegular', <String>[
    '$fa/lib/fonts/Font-Awesome-7-Free-Regular-400.otf',
  ]);
}

void main() {
  setUpAll(_loadFonts);

  const phone = Size(390, 844);
  const tablet = Size(800, 1000);

  testWidgets('Verlauf Handy 390', (tester) async {
    await _show(tester, const HistoryScreen(), size: phone);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/history_390.png'),
    );
  });

  testWidgets('Verlauf Tablet 800', (tester) async {
    await _show(tester, const HistoryScreen(), size: tablet);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/history_800.png'),
    );
  });

  testWidgets('Favoriten leer Handy 390', (tester) async {
    await _show(tester, const FavoritesScreen(), size: phone);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/favorites_empty_390.png'),
    );
  });

  testWidgets('Favoriten gefuellt Handy 390', (tester) async {
    await _show(
      tester,
      const FavoritesScreen(),
      size: phone,
      favorites: <Favorite>[
        _f('Waterfall', 'Michael Calfan & Ofenbach', 'linefm'),
        _f('Last Night', 'Bruno Mars', 'linefmrap'),
        _f(
          'Ein sehr langer Songtitel der garantiert nicht in die Zeile passt',
          'Interpretin mit ebenfalls langem Namen',
          'linefmlofi',
        ),
        _f('Smooth My Heart', 'Anne-Marie', 'fobfm'),
      ],
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/favorites_390.png'),
    );
  });
}
