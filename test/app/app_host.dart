import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/app.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/live/now_playing_repository.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/loader/app_loader.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:material_ui/material_ui.dart';

const Track trackMain = Track(artist: 'James Hype', title: "I Was Lovin' You");
const Track trackRap = Track(
  artist: 'Kontra K',
  title: 'Erfolg ist kein Glück',
);

/// Sammelt Telemetrie-Ereignisse als Text (`play {station: linefm}`).
class RecordingSink implements AnalyticsSink {
  final List<String> events = <String>[];

  List<String> get names =>
      events.map((e) => e.split(' ').first).toList(growable: false);

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

/// Live-Daten ohne Netz mit steuerbarem Online-Zustand.
class TestRepository extends FakeNowPlayingRepository {
  TestRepository({this.online = true})
    : super(
        tracks: const <String, Track>{
          'linefm': trackMain,
          'linefmrap': trackRap,
        },
        history: const <HistoryEntry>[
          HistoryEntry(track: trackMain, isLive: true),
        ],
        listeners: 42,
      );

  final bool online;
  final List<String> calls = <String>[];

  @override
  Stream<bool> watchOnline() => Stream<bool>.value(online);

  @override
  void setActiveStation(Station station) => calls.add('active:${station.slug}');

  @override
  void setForeground({required bool value}) => calls.add('foreground:$value');

  @override
  void setPlaying({required bool value}) => calls.add('playing:$value');
}

/// Komplette App mit Stubs (kein Netz, kein Audio).
class AppHost {
  AppHost({
    InMemoryPrefsStore? prefs,
    AppSettings? settings,
    this.repository,
    this.extra = const <Override>[],
  }) : prefs = prefs ?? InMemoryPrefsStore() {
    if (settings != null) this.prefs.writeSettings(settings).ignore();
  }

  final InMemoryPrefsStore prefs;
  final NoopPlaybackService playback = NoopPlaybackService();
  final RecordingSink sink = RecordingSink();
  TestRepository? repository;
  final List<Override> extra;

  late final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      prefsProvider.overrideWithValue(prefs),
      playbackServiceProvider.overrideWithValue(playback),
      nowPlayingRepositoryProvider.overrideWith((ref) {
        final repo = repository ??= TestRepository();
        bindNowPlayingRepository(ref, repo);
        return repo;
      }),
      telemetryProvider.overrideWithValue(
        TelemetryHub(
          config: const AppConfig(
            umamiUrl: 'https://u.example',
            umamiWebsiteId: 'x',
          ),
          analytics: <AnalyticsSink>[sink],
          consent: true,
        ),
      ),
      // Einwilligung bereits erteilt: kein Dialog im Test.
      telemetryConsentProvider.overrideWith(_ConsentGiven.new),
      ...extra,
    ],
  );

  Widget app({Uri? launchUri}) => UncontrolledProviderScope(
    container: container,
    child: LinefmApp(launchUri: launchUri),
  );

  Station get active => container.read(activeStationProvider);
}

class _ConsentGiven extends TelemetryConsentNotifier {
  @override
  bool? build() => true;
}

/// Fenstergroesse in logischen Pixeln.
void useSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Startet die App ohne Ladebildschirm und wartet die ersten Daten ab.
Future<void> pumpApp(WidgetTester tester, AppHost host, {Uri? uri}) async {
  loaderShownThisProcess = true;
  // Ohne Angabe Deutsch (Testumgebung meldet en_US).
  await tester.pumpWidget(
    host.app(launchUri: uri ?? Uri.parse('https://app.linefm.de/?lang=de')),
  );
  await settleApp(tester);
}

/// Wie `pumpAndSettle`, ohne auf Endlos-Animationen (Lauftext) zu warten.
Future<void> settleApp(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Baut die App ab, damit Timer und Abos enden.
Future<void> disposeApp(WidgetTester tester, AppHost host) async {
  await tester.pumpWidget(const SizedBox.shrink());
  host.container.dispose();
}

/// Erster Sender, der nicht [s] ist.
Station otherThan(Station s) => stationsCatalog.firstWhere((x) => x != s);
