import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/history/icon_action.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

import '../support/in_memory_prefs_store.dart';
import '../support/service_doubles.dart';
import '../support/test_doubles.dart';

class Repo extends FakeNowPlayingRepository {
  Repo(this.entries);

  final List<HistoryEntry> entries;
  int refreshes = 0;

  @override
  Stream<List<HistoryEntry>> watchHistory(Station station) =>
      Stream<List<HistoryEntry>>.value(entries);

  @override
  Future<void> refresh() async => refreshes++;
}

class Telemetry extends TelemetryHub {
  Telemetry() : super(config: AppConfig.fromEnvironment());

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

class Share extends NoopShareService {
  Share({this.fail = false});

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
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Finder action(String label) => find.byWidgetPredicate(
  (w) => w is IconAction && w.label == label,
  description: 'IconAction "$label"',
);

final DateTime t = DateTime(2026, 11, 18, 21, 5);

List<HistoryEntry> entries() => <HistoryEntry>[
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

Favorite fav(String title, String artist, {String station = 'linefm'}) =>
    Favorite(
      key: '$station:${artist.toLowerCase()}:${title.toLowerCase()}',
      stationSlug: station,
      title: title,
      artist: artist,
      savedAt: t,
    );

Future<
  ({
    ProviderContainer container,
    Telemetry telemetry,
    Share share,
    Repo repo,
    InMemoryPrefsStore prefs,
  })
>
pumpScreen(
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
  final telemetry = Telemetry();
  final shareService = Share(fail: shareFails);
  final repo = Repo(history ?? entries());
  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      telemetryProvider.overrideWithValue(telemetry),
      shareServiceProvider.overrideWithValue(shareService),
      nowPlayingRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(FakeClock(t)),
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
  await settle(tester);
  return (
    container: container,
    telemetry: telemetry,
    share: shareService,
    repo: repo,
    prefs: prefs,
  );
}
