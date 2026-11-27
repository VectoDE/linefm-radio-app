// ignore: depend_on_referenced_packages
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations, GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart' show WidgetTester;
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/stations/station_actions.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_doubles.dart';

const Track trackMain = Track(artist: 'James Hype', title: "I Was Lovin' You");
const Track trackRap = Track(
  artist: 'Ein Kuenstler mit sehr langem Namen',
  title: 'Ein ebenso langer Songtitel der nicht in die Karte passt',
);

/// Sammelt Telemetrie-Ereignisse.
class RecordingSink implements AnalyticsSink {
  final List<String> events = <String>[];

  @override
  Future<void> init() async {}

  @override
  Future<void> screen(String name) async => events.add('screen:$name');

  @override
  Future<void> event(
    String name, [
    Map<String, Object> props = const {},
  ]) async {
    events.add(props.isEmpty ? name : '$name $props');
  }

  @override
  Future<void> setEnabled({required bool enabled}) async {}
}

class Harness {
  Harness({
    this.brightness = Brightness.dark,
    this.locale = const Locale('de'),
    this.extra = const <Override>[],
  });

  final List<Override> extra;
  final Brightness brightness;
  final Locale locale;
  final RecordingSink sink = RecordingSink();
  final NoopPlaybackService playback = NoopPlaybackService();
  final List<String> shared = <String>[];
  late final ProviderContainer container = ProviderContainer(
    overrides: overrides,
  );

  List<Override> get overrides => <Override>[
    prefsProvider.overrideWithValue(InMemoryPrefsStore()),
    nowPlayingRepositoryProvider.overrideWithValue(
      FakeNowPlayingRepository(
        tracks: <String, Track>{'linefm': trackMain, 'linefmrap': trackRap},
      ),
    ),
    playbackServiceProvider.overrideWithValue(playback),
    telemetryProvider.overrideWith((ref) {
      final hub = TelemetryHub(
        config: const AppConfig(
          umamiUrl: 'https://u.example',
          umamiWebsiteId: 'x',
        ),
        analytics: <AnalyticsSink>[sink],
        consent: true,
      );
      return hub;
    }),
    stationShareFnProvider.overrideWithValue((text) async => shared.add(text)),
    ...extra,
  ];

  Widget app(Widget child) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLinefmTheme(brightness),
      locale: locale,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

/// Wie `pumpAndSettle`, aber ohne auf Endlos-Animationen (Lauftext,
/// Wiedergabe-Balken) zu warten.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}
