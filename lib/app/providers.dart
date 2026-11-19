import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/player_controller.dart';
import 'package:linefm_radio/app/system_share_service.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/api/http_cache.dart';
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/data/api/song_change_socket.dart';
import 'package:linefm_radio/data/artwork/itunes_artwork.dart';
import 'package:linefm_radio/data/live/now_playing_repository.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/alarm/alarm_schedule.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_logic.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/now_playing.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/alarm/alarm_wiring.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/share/share_service.dart';
import 'package:linefm_radio/services/sleep_timer/sleep_timer_service.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/services/widgets/home_widget_sync.dart';

// Zentrale Provider-Definitionen (Spec 3.4). Gemeinsame Datei: Besitz P01,
// danach P11/P28. Aenderungswuensche anderer Pakete laufen ueber den Bericht.
//
// Die Standardwerte sind Stubs ohne Netzwerk (Tests, Previews). main() setzt
// die echten Dienste ueber [productionOverrides].

// ---------------------------------------------------------------- Konfig/Kern

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// Wird in main() per Override gesetzt.
final prefsProvider = Provider<PrefsStore>(
  (ref) => throw UnimplementedError('prefsProvider muss ueberschrieben werden'),
);

final telemetryProvider = Provider<TelemetryHub>(
  (ref) => TelemetryHub.noop(ref.watch(appConfigProvider)),
);

// ------------------------------------------------------------------- Dienste

final lautApiProvider = Provider<LautApi>((ref) => const StubLautApi());

final artworkProvider = Provider<ArtworkService>(
  (ref) => const NoopArtworkService(),
);

final nowPlayingRepositoryProvider = Provider<NowPlayingRepository>((ref) {
  final repo = FakeNowPlayingRepository();
  bindNowPlayingRepository(ref, repo);
  return repo;
});

/// Bindet den Live-Daten-Motor an die App: gewaehlte Station und laufende
/// Wiedergabe steuern Timer und Abrufe; `dispose` beendet Timer und
/// WebSocket. Den Vordergrund meldet die Shell (`setForeground`).
void bindNowPlayingRepository(Ref ref, NowPlayingRepository repo) {
  ref
    ..listen<Station>(
      activeStationProvider,
      (_, next) => repo.setActiveStation(next),
    )
    ..listen<AsyncValue<PlayerUiState>>(playerStateProvider, (_, next) {
      final state = next.value;
      if (state != null) {
        repo.setPlaying(value: state.isPlaying || state.isBusy);
      }
    })
    ..onDispose(repo.dispose);
}

/// Audio-Dienst; main() setzt das Ergebnis von initAudio().
final playbackServiceProvider = Provider<PlaybackService>((ref) {
  final service = NoopPlaybackService();
  ref.onDispose(service.dispose);
  return service;
});

final castServiceProvider = Provider<CastService>(
  (ref) => const NoopCastService(),
);

final shareServiceProvider = Provider<ShareService>(
  (ref) => const NoopShareService(),
);

final homeWidgetSyncProvider = Provider<HomeWidgetSync>(
  (ref) => const NoopHomeWidgetSync(),
);

final sleepTimerServiceProvider = Provider<SleepTimerService>(
  (ref) => const NoopSleepTimerService(),
);

final alarmCoordinatorProvider = Provider<AlarmCoordinator>(
  (ref) => const NoopAlarmCoordinator(),
);

final playerControllerProvider = Provider<PlayerController>(
  PlayerController.new,
);

// ------------------------------------------------------------ Live-Zustand

final stationsProvider = StreamProvider<List<StationLive>>(
  (ref) => ref.watch(nowPlayingRepositoryProvider).watchStations(),
);

class ActiveStationNotifier extends Notifier<Station> {
  @override
  Station build() {
    final slug = ref.read(prefsProvider).readLastStation();
    return (slug == null ? null : stationBySlug(slug)) ?? stationsCatalog.first;
  }

  void select(Station station) {
    state = station;
    ref.read(prefsProvider).writeLastStation(station.slug).ignore();
  }
}

final activeStationProvider = NotifierProvider<ActiveStationNotifier, Station>(
  ActiveStationNotifier.new,
);

final playerStateProvider = StreamProvider<PlayerUiState>((ref) async* {
  final service = ref.watch(playbackServiceProvider);
  yield service.state;
  yield* service.stateStream;
});

final currentTrackProvider = Provider<AsyncValue<Track?>>((ref) {
  final active = ref.watch(activeStationProvider);
  return ref
      .watch(stationsProvider)
      .whenData(
        (list) => list
            .where((s) => s.station == active)
            .map((s) => s.track)
            .firstOrNull,
      );
});

/// LIVE-Eintrag plus letzte Songs der gewaehlten Station, live aktualisiert.
final historyProvider = StreamProvider<List<HistoryEntry>>((ref) {
  final station = ref.watch(activeStationProvider);
  return ref.watch(nowPlayingRepositoryProvider).watchHistory(station);
});

final listenersProvider = StreamProvider<int?>((ref) {
  final station = ref.watch(activeStationProvider);
  return ref.watch(nowPlayingRepositoryProvider).watchListeners(station);
});

/// `false`, solange laut.fm nicht erreichbar ist (Offline-Leiste).
final onlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(nowPlayingRepositoryProvider).watchOnline(),
);

// ----------------------------------------------------------- Persistiert

class FavoritesNotifier extends Notifier<List<Favorite>> {
  @override
  List<Favorite> build() => ref.read(prefsProvider).readFavorites();

  void toggle(Favorite favorite) {
    state = FavoritesLogic.toggle(state, favorite);
    ref.read(prefsProvider).writeFavorites(state).ignore();
  }

  void remove(String key) {
    state = FavoritesLogic.remove(state, key);
    ref.read(prefsProvider).writeFavorites(state).ignore();
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<Favorite>>(
  FavoritesNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(prefsProvider).readSettings();

  void update(AppSettings Function(AppSettings current) change) {
    state = change(state);
    ref.read(prefsProvider).writeSettings(state).ignore();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Speicher-Bestaetigung (Speicher-Hinweis, auf allen Plattformen).
class StorageConsentNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(prefsProvider).storageConsent;

  Future<void> set({required bool value}) async {
    state = value;
    await ref.read(prefsProvider).setStorageConsent(value: value);
  }
}

final storageConsentProvider = NotifierProvider<StorageConsentNotifier, bool>(
  StorageConsentNotifier.new,
);

/// null = noch nicht entschieden.
class TelemetryConsentNotifier extends Notifier<bool?> {
  @override
  bool? build() => ref.read(prefsProvider).readTelemetryConsent();

  Future<void> set({required bool? value}) async {
    state = value;
    await ref.read(prefsProvider).writeTelemetryConsent(value: value);
    await ref.read(telemetryProvider).setConsent(value: value ?? false);
  }
}

final telemetryConsentProvider =
    NotifierProvider<TelemetryConsentNotifier, bool?>(
      TelemetryConsentNotifier.new,
    );

// ------------------------------------------------------- Timer, Wecker, Cast

class SleepTimerNotifier extends Notifier<SleepTimerState> {
  @override
  SleepTimerState build() {
    final service = ref.watch(sleepTimerServiceProvider);
    // Ablauf, Ausblenden und Restzeit meldet der Dienst selbst.
    final sub = service.states.listen((s) => state = s);
    ref.onDispose(sub.cancel);
    return service.state;
  }

  Future<void> start(SleepTimerMode mode, {Track? currentTrack}) async {
    final service = ref.read(sleepTimerServiceProvider);
    await service.start(mode, currentTrack: currentTrack);
    state = service.state;
  }

  Future<void> cancel() async {
    final service = ref.read(sleepTimerServiceProvider);
    await service.cancel();
    state = service.state;
  }
}

final sleepTimerProvider =
    NotifierProvider<SleepTimerNotifier, SleepTimerState>(
      SleepTimerNotifier.new,
    );

class AlarmNotifier extends Notifier<List<AlarmRule>> {
  @override
  List<AlarmRule> build() {
    final stored = ref.read(prefsProvider).readAlarms();
    // Aeltere einmalige Regeln ohne festen Termin bekommen ihn jetzt.
    return AlarmSchedule.withFiresAt(
      stored,
      stored,
      ref.read(clockProvider).now(),
    );
  }

  Future<void> setRules(List<AlarmRule> rules) async {
    // Einmalige Regeln bekommen beim Einschalten/Aendern ihren festen Termin.
    final next = AlarmSchedule.withFiresAt(
      rules,
      state,
      ref.read(clockProvider).now(),
    );
    state = next;
    await ref.read(prefsProvider).writeAlarms(next);
    await ref.read(alarmCoordinatorProvider).rescheduleAll(next);
  }
}

final alarmProvider = NotifierProvider<AlarmNotifier, List<AlarmRule>>(
  AlarmNotifier.new,
);

final castProvider = StreamProvider<CastState>(
  (ref) => ref.watch(castServiceProvider).states,
);

// --------------------------------------------------------------- Navigation

final navigationProvider = NotifierProvider<NavigationNotifier, AppScreen>(
  NavigationNotifier.new,
);

// ------------------------------------------------------------- Produktion

/// Echte Dienste fuer main(): laut.fm-REST mit Cache, iTunes-Cover mit
/// persistentem Cache, Live-Daten-Motor (WebSocket nur mit `WS_ENABLED=true`,
/// Standard aus, Entscheidung 50), System-Teilen. [httpClient] nur fuer
/// Tests; ohne Angabe erzeugt jeder Dienst seinen eigenen Client.
List<Override> productionOverrides({
  required AppConfig config,
  required PrefsStore prefs,
  required PlaybackService playback,
  required TelemetryHub telemetry,
  http.Client? httpClient,
}) => <Override>[
  appConfigProvider.overrideWithValue(config),
  prefsProvider.overrideWithValue(prefs),
  playbackServiceProvider.overrideWithValue(playback),
  telemetryProvider.overrideWithValue(telemetry),
  lautApiProvider.overrideWith((ref) {
    final api = HttpLautApi(cache: HttpCache(client: httpClient));
    if (httpClient == null) ref.onDispose(api.close);
    return api;
  }),
  artworkProvider.overrideWith((ref) {
    final service = ItunesArtworkService(
      client: httpClient,
      clock: ref.watch(clockProvider),
      store: CoverCacheStore(
        read: prefs.readCoverCache,
        write: prefs.writeCoverCache,
      ),
    );
    ref.onDispose(() {
      unawaited(httpClient == null ? service.dispose() : service.flush());
    });
    return service;
  }),
  nowPlayingRepositoryProvider.overrideWith((ref) {
    final repo = LiveNowPlayingRepository(
      api: ref.watch(lautApiProvider),
      artwork: ref.watch(artworkProvider),
      clock: ref.watch(clockProvider),
      activeStation: ref.read(activeStationProvider),
      socket: config.wsEnabled ? WebSocketSongChangeSocket() : null,
    );
    bindNowPlayingRepository(ref, repo);
    return repo;
  }),
  homeWidgetSyncProvider.overrideWithValue(createHomeWidgetSync()),
  shareServiceProvider.overrideWith(
    (ref) => SystemShareService(webBaseUrl: config.webBaseUrl),
  ),
  ...alarmAndSleepOverrides(),
];
