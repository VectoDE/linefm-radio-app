import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/player_controller.dart';
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
import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/app/stations_provider.dart';
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
    // Nachgeladene Senderliste (Issue #91): geaenderte Angaben des aktiven
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
    unawaited(
      ref.read(prefsProvider).writeFavorites(state).catchError(_logPrefsError),
    );
  }

  void remove(String key) {
    state = FavoritesLogic.remove(state, key);
    unawaited(
      ref.read(prefsProvider).writeFavorites(state).catchError(_logPrefsError),
    );
  }

  /// "Rueckgaengig" nach dem Entfernen (U3): setzt [favorite] wieder an
  /// [index]. Ist er inzwischen wieder da, bleibt die Liste unveraendert.
  void restore(Favorite favorite, int index) {
    if (FavoritesLogic.contains(state, favorite.key)) return;
    final next = <Favorite>[...state]
      ..insert(index.clamp(0, state.length), favorite);
    state = next;
    unawaited(
      ref.read(prefsProvider).writeFavorites(state).catchError(_logPrefsError),
    );
  }

  /// Fuehrt importierte Favoriten mit den vorhandenen zusammen (Doppelte
  /// zaehlen einmal) und liefert die Zahl der neuen.
  int importFavorites(List<Favorite> imported) {
    final merged = FavoritesImport.merge(state, imported);
    state = merged.favorites;
    unawaited(
      ref.read(prefsProvider).writeFavorites(state).catchError(_logPrefsError),
    );
    return merged.added;
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
    unawaited(
      ref.read(prefsProvider).writeSettings(state).catchError(_logPrefsError),
    );
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
    // Schalter "Cover laden" aus: keine Anfrage an
    // Apple, nur Cover aus der laut.fm-API, sonst Senderlogo (L5).
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

/// Speicherfehler nicht verschlucken (Q-14): loggen; die Daten bleiben im
/// Speicher der laufenden App und werden beim naechsten Schreiben erneut
/// gesichert.
void _logPrefsError(Object error, StackTrace stack) =>
    logError('Speichern fehlgeschlagen', error, stack);
