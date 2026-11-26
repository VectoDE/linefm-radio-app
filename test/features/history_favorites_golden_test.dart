@Tags(<String>['golden'])
library;

// Visueller Abgleich gegen die Web-App (Referenz: Screenshots in `_input/`,
// Handy 390 dp, Tablet 800 dp) in Dark und Hell. Referenzbilder entstehen auf
// dem CI-Runner, siehe docs/ENTWICKLUNG.md ("Goldens aktualisieren").
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
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

import '../golden_support.dart';
import '../support/test_doubles.dart';

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
  savedAt: DateTime(2026, 11, 18, 20),
);

Future<void> _show(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  required Brightness brightness,
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
        theme: buildLinefmTheme(brightness),
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

Future<void> _matches(String name, Brightness brightness) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/${name}_${variant(brightness)}.png'),
);

void main() {
  setUpAll(prepareGoldens);

  const phone = Size(390, 844);
  const tablet = Size(800, 1000);

  for (final brightness in Brightness.values) {
    group('Golden ${variant(brightness)}', () {
      testWidgets('Verlauf Handy 390', (tester) async {
        await _show(
          tester,
          const HistoryScreen(),
          size: phone,
          brightness: brightness,
        );
        await _matches('history_390', brightness);
      });

      testWidgets('Verlauf Tablet 800', (tester) async {
        await _show(
          tester,
          const HistoryScreen(),
          size: tablet,
          brightness: brightness,
        );
        await _matches('history_800', brightness);
      });

      testWidgets('Favoriten leer Handy 390', (tester) async {
        await _show(
          tester,
          const FavoritesScreen(),
          size: phone,
          brightness: brightness,
        );
        await _matches('favorites_empty_390', brightness);
      });

      testWidgets('Favoriten gefuellt Handy 390', (tester) async {
        await _show(
          tester,
          const FavoritesScreen(),
          size: phone,
          brightness: brightness,
          favorites: <Favorite>[
            _f('Waterfall', 'Michael Calfan & Ofenbach', 'linefm'),
            _f('Last Night', 'Bruno Mars', 'linefmrap'),
            _f(
              'Ein sehr langer Songtitel der garantiert nicht in die Zeile '
                  'passt',
              'Interpretin mit ebenfalls langem Namen',
              'linefmlofi',
            ),
            _f('Smooth My Heart', 'Anne-Marie', 'fobfm'),
          ],
        );
        await _matches('favorites_390', brightness);
      });
    });
  }
}
