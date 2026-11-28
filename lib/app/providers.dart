import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/player_controller.dart';
import 'package:linefm_radio/app/stations_provider.dart';
import 'package:linefm_radio/app/user_activation.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/core/logging.dart';
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
import 'package:linefm_radio/domain/favorites/favorites_import.dart';
import 'package:linefm_radio/domain/favorites/favorites_logic.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/now_playing.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/schedule_slot.dart';
import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/alarm/alarm_wiring.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_handoff.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/cast/chrome_cast_service.dart';
import 'package:linefm_radio/services/share/share_service.dart';
import 'package:linefm_radio/services/share/system_share_service.dart';
import 'package:linefm_radio/services/sleep_timer/sleep_timer_service.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/services/widgets/home_widget_sync.dart';

part 'providers_state.dart';

// Zentrale Provider-Definitionen (Spec 3.4). Gemeinsame Datei: Besitz P01,
// danach P11/P28. Aenderungswuensche anderer Pakete laufen ueber den Bericht.
//
// Services without a safe built-in fallback throw until overridden; main()
// sets the real ones via [productionOverrides], tests via test/support.

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

/// Set by productionOverrides(); tests use their own doubles.
final lautApiProvider = Provider<LautApi>(
  (ref) => throw UnimplementedError('lautApiProvider must be overridden'),
);

/// Schedule of a station (slug); empty on error or without a schedule.
final stationScheduleProvider =
    FutureProvider.family<List<ScheduleSlot>, String>((ref, slug) async {
      try {
        return await ref.watch(lautApiProvider).schedule(slug);
      } on Exception {
        return const <ScheduleSlot>[];
      }
    });

/// Set by productionOverrides(); tests use their own doubles.
final artworkProvider = Provider<ArtworkService>(
  (ref) => throw UnimplementedError('artworkProvider must be overridden'),
);

/// Set by productionOverrides(); tests use their own doubles.
final nowPlayingRepositoryProvider = Provider<NowPlayingRepository>(
  (ref) => throw UnimplementedError(
    'nowPlayingRepositoryProvider must be overridden',
  ),
);

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

/// Chromecast: echter Dienst, wenn [castBackend] (initCast) existiert, sonst
/// [NoopCastService]. Bindet Übergabe lokal zu Cast, Titel-Metadaten und
/// Lautstärke an die Wiedergabe. Wird beim ersten Lesen erzeugt (Cast-Knopf
/// im Player); die Shell kann ihn für Sitzungen aus früheren Läufen früher
/// lesen.
CastService createCastService(Ref ref) {
  final backend = castBackend;
  if (backend == null) return const NoopCastService();
  final lautApi = ref.read(lautApiProvider);
  final service = ChromeCastService(
    backend: backend,
    resolveStreamUrl: (station) => resolveCastStreamUrl(lautApi, station),
  );
  final playback = ref.read(playbackServiceProvider);
  final handoff = CastHandoff(
    service: service,
    stopLocal: playback.stopPlayback,
    activeStation: () => ref.read(activeStationProvider),
    currentTrack: () => ref.read(currentTrackProvider).value,
    initialVolume: playback.state.volume,
  );
  final subs = <StreamSubscription<Object?>>[
    service.states.listen((state) {
      handoff.onCastState(state);
      // Player-Anzeige: laeuft ein Sender am Geraet, zeigt der Player "Stop".
      ref.read(castPlaybackProvider.notifier).set(state);
    }),
    playback.stateStream.listen(handoff.onLocalState),
  ];
  ref
    ..listen<AsyncValue<Track?>>(
      currentTrackProvider,
      (_, next) => handoff.onTrack(next.value),
    )
    ..onDispose(() {
      for (final sub in subs) {
        unawaited(sub.cancel());
      }
      unawaited(service.dispose());
    });
  return service;
}

/// Letzter Zustand der Cast-Sitzung fuer die Player-Anzeige. Schreibt nur
/// [createCastService]; ohne eigene Abhaengigkeiten, damit
/// [playerStateProvider] ihn lesen kann, ohne einen Zyklus ueber den
/// Live-Daten-Motor zu bilden.
class CastPlaybackNotifier extends Notifier<CastState> {
  @override
  CastState build() => const CastState();

  // ignore: use_setters_to_change_properties
  void set(CastState next) => state = next;
}

final castPlaybackProvider = NotifierProvider<CastPlaybackNotifier, CastState>(
  CastPlaybackNotifier.new,
);

/// Zustand fuer die Anzeige: lokale Wiedergabe, bei laufender Cast-
/// Wiedergabe (lokal still) "spielt" der Cast-Sender.
PlayerUiState mergeCastPlayback(PlayerUiState local, CastState cast) {
  if (!cast.isPlayingMedia || local.isPlaying || local.isBusy) return local;
  return local.copyWith(status: PlayerStatus.playing, station: cast.station);
}

/// Web: Hat der Nutzer schon mit der Seite interagiert? Ohne Interaktion
/// blockieren Browser den Ton (Autoplay-Sperre). Ausserhalb des Webs immer
/// `true`. Tests ueberschreiben die Pruefung.
final userActivationProvider = Provider<bool Function()>(
  (ref) => hasUserActivation,
);

/// Web: Ein Start wurde von der Autoplay-Sperre aufgehalten (Autoplay beim
/// Start, Wecker, Link). Die Shell zeigt dann den Knopf "Radio starten".
class AutoplayBlockedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set({required bool value}) => state = value;
}

final autoplayBlockedProvider = NotifierProvider<AutoplayBlockedNotifier, bool>(
  AutoplayBlockedNotifier.new,
);

/// Set by productionOverrides(); tests use their own doubles.
final playbackServiceProvider = Provider<PlaybackService>(
  (ref) =>
      throw UnimplementedError('playbackServiceProvider must be overridden'),
);

final castServiceProvider = Provider<CastService>(
  (ref) => const NoopCastService(),
);

/// Set by productionOverrides(); tests use their own doubles.
final shareServiceProvider = Provider<ShareService>(
  (ref) => throw UnimplementedError('shareServiceProvider must be overridden'),
);

final homeWidgetSyncProvider = Provider<HomeWidgetSync>(
  (ref) => const NoopHomeWidgetSync(),
);

/// Set by productionOverrides(); tests use their own doubles.
final sleepTimerServiceProvider = Provider<SleepTimerService>(
  (ref) =>
      throw UnimplementedError('sleepTimerServiceProvider must be overridden'),
);

/// Set by productionOverrides(); tests use their own doubles.
final alarmCoordinatorProvider = Provider<AlarmCoordinator>(
  (ref) =>
      throw UnimplementedError('alarmCoordinatorProvider must be overridden'),
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
    // Nachgeladene Senderliste: geaenderte Angaben des aktiven
    // Senders (Name, Farbe, Logo) uebernehmen. Wurde er entfernt, bleibt er
    // aktiv, bis der Nutzer wechselt; eine laufende Wiedergabe reisst nicht
    // ab.
    ref.listen(stationsCatalogProvider, (_, next) {
      final updated = stationBySlug(state.slug);
      if (updated != null && !updated.sameAs(state)) state = updated;
    });
    final slug = ref.read(prefsProvider).readLastStation();
    return (slug == null ? null : stationBySlug(slug)) ?? stationsCatalog.first;
  }

  void select(Station station) {
    state = station;
    unawaited(
      ref
          .read(prefsProvider)
          .writeLastStation(station.slug)
          .catchError(_logPrefsError),
    );
  }
}

final activeStationProvider = NotifierProvider<ActiveStationNotifier, Station>(
  ActiveStationNotifier.new,
);

/// Zustand des Players fuer die Anzeige (lokal plus Cast, siehe
/// [mergeCastPlayback]).
final playerStateProvider = StreamProvider<PlayerUiState>((ref) async* {
  final service = ref.watch(playbackServiceProvider);
  final cast = ref.watch(castPlaybackProvider);
  yield mergeCastPlayback(service.state, cast);
  yield* service.stateStream.map((s) => mergeCastPlayback(s, cast));
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

/// Hoererzahl der aktiven Station; null (und kein Abruf), solange
/// `showListenerCount` in config/features.yaml nicht true ist.
final listenersProvider = StreamProvider<int?>((ref) {
  if (!ref.watch(appConfigProvider).showListenerCount) {
    return Stream<int?>.value(null);
  }
  final station = ref.watch(activeStationProvider);
  return ref.watch(nowPlayingRepositoryProvider).watchListeners(station);
});

/// `false`, solange laut.fm nicht erreichbar ist (Offline-Leiste).
final onlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(nowPlayingRepositoryProvider).watchOnline(),
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
    // Schalter "Cover laden" aus: keine Anfrage an
    // Apple, nur Cover aus der laut.fm-API, sonst Senderlogo.
    if (!ref.watch(settingsProvider.select((s) => s.loadArtwork))) {
      return const ApiCoverOnlyArtworkService();
    }
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
      readSnapshot: ref.read(prefsProvider).readLiveCache,
      writeSnapshot: ref.read(prefsProvider).writeLiveCache,
    );
    ref.listen(stationsCatalogProvider, (_, _) => repo.stationsChanged());
    bindNowPlayingRepository(ref, repo);
    return repo;
  }),
  homeWidgetSyncProvider.overrideWithValue(createHomeWidgetSync()),
  shareServiceProvider.overrideWith(
    (ref) => SystemShareService(webBaseUrl: config.webBaseUrl),
  ),
  ...alarmAndSleepOverrides(),
  castServiceProvider.overrideWith(createCastService),
];

/// Speicherfehler nicht verschlucken: loggen; die Daten bleiben im
/// Speicher der laufenden App und werden beim naechsten Schreiben erneut
/// gesichert.
void _logPrefsError(Object error, StackTrace stack) =>
    logError('Speichern fehlgeschlagen', error, stack);
