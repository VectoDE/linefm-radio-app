import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/player_controller.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/platform/deep_links.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/services/widgets/home_widget_sync.dart';

import 'app_host.dart';

/// Wiedergabe mit steuerbarem Fehler.
class _Playback extends NoopPlaybackService {
  final List<String> calls = <String>[];

  List<String> get plays =>
      calls.where((c) => c.startsWith('play:')).toList(growable: false);

  final StreamController<PlayerUiState> _states =
      StreamController<PlayerUiState>.broadcast();
  PlayerUiState _s = const PlayerUiState();

  @override
  PlayerUiState get state => _s;

  @override
  Stream<PlayerUiState> get stateStream => _states.stream;

  void emit(PlayerUiState s) {
    _s = s;
    _states.add(s);
  }

  @override
  Future<void> playStation(Station station) async {
    calls.add('play:${station.slug}');
    emit(_s.copyWith(status: PlayerStatus.connecting, station: station));
    emit(_s.copyWith(status: PlayerStatus.playing));
  }

  @override
  Future<void> stopPlayback() async {
    calls.add('stop');
    emit(_s.copyWith(status: PlayerStatus.idle));
  }

  @override
  Future<void> setVolume(double volume) async {
    calls.add('volume:$volume');
    emit(_s.copyWith(volume: volume));
  }

  @override
  Future<void> updateNowPlaying(Station station, Track? track) async =>
      calls.add('now:${station.slug}:${track?.title}');
}

class _Widget implements HomeWidgetSync {
  final List<String> updates = <String>[];

  @override
  Future<void> update({
    Station? station,
    Track? track,
    required bool playing,
  }) async => updates.add('${station?.slug}:${track?.title}:$playing');
}

class _Ctx {
  _Ctx({
    AppSettings settings = const AppSettings(),
    String? lastStation,
    double? volume,
    bool Function()? activation,
    CastService? cast,
  }) {
    prefs.writeSettings(settings).ignore();
    if (lastStation != null) prefs.writeLastStation(lastStation).ignore();
    if (volume != null) prefs.writeVolume(volume).ignore();
    container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        playbackServiceProvider.overrideWithValue(playback),
        homeWidgetSyncProvider.overrideWithValue(widget),
        if (activation != null)
          userActivationProvider.overrideWithValue(activation),
        if (cast != null) castServiceProvider.overrideWithValue(cast),
        nowPlayingRepositoryProvider.overrideWith((ref) {
          final repo = TestRepository();
          bindNowPlayingRepository(ref, repo);
          return repo;
        }),
        telemetryProvider.overrideWithValue(
          TelemetryHub(
            config: const AppConfig(umamiUrl: 'https://u', umamiWebsiteId: 'x'),
            analytics: <AnalyticsSink>[sink],
            consent: true,
          ),
        ),
      ],
    );
    // Wie die Shell: dauerhaft abonniert, sonst pausiert Riverpod 3 die
    // Provider samt ihrer ref.listen-Abos.
    container
      ..listen(playerControllerProvider, (_, _) {})
      ..listen(nowPlayingRepositoryProvider, (_, _) {});
  }

  final prefs = InMemoryPrefsStore();
  final playback = _Playback();
  final widget = _Widget();
  final sink = RecordingSink();
  late final ProviderContainer container;

  PlayerController get controller => container.read(playerControllerProvider);
  Station get active => container.read(activeStationProvider);

  void dispose() => container.dispose();
}

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  test('secondsBucket: grobe Klassen', () {
    expect(secondsBucket(0), '<10');
    expect(secondsBucket(59), '10-59');
    expect(secondsBucket(3600), '3600+');
  });

  group('Telemetrie an einer Stelle', () {
    test('Start und Stop melden je genau ein play/stop', () async {
      final c = _Ctx();
      addTearDown(c.dispose);
      await c.controller.startStation(stationsCatalog[1]);
      await _flush();
      await c.controller.togglePlayback();
      await _flush();
      expect(c.sink.events, <String>[
        'play {station: linefmrap}',
        'stop {station: linefmrap, seconds_bucket: <10}',
      ]);
      expect(c.active, stationsCatalog[1]);
    });

    test('Senderwechsel waehrend der Wiedergabe: stop alt, play neu', () async {
      final c = _Ctx();
      addTearDown(c.dispose);
      await c.controller.startStation(stationsCatalog[0]);
      await _flush();
      await c.controller.startStation(stationsCatalog[2]);
      await _flush();
      expect(c.sink.names, <String>['play', 'stop', 'play']);
      expect(c.sink.events.last, 'play {station: linefmgaming}');
    });

    test('Neuverbindung zaehlt nicht doppelt', () async {
      final c = _Ctx();
      addTearDown(c.dispose);
      await c.controller.startStation(stationsCatalog[0]);
      await _flush();
      c.playback
        ..emit(c.playback.state.copyWith(status: PlayerStatus.reconnecting))
        ..emit(c.playback.state.copyWith(status: PlayerStatus.playing));
      await _flush();
      expect(c.sink.names, <String>['play']);
    });

    test('Fehler meldet error_stream, kein stop', () async {
      final c = _Ctx();
      addTearDown(c.dispose);
      c.controller; // Controller anlegen (abonniert den Zustand).
      c.playback
        ..emit(
          PlayerUiState(
            status: PlayerStatus.connecting,
            station: stationsCatalog[3],
          ),
        )
        ..emit(c.playback.state.copyWith(status: PlayerStatus.error));
      await _flush();
      expect(c.sink.events, <String>[
        'play {station: linefmlofi}',
        'error_stream {station: linefmlofi}',
      ]);
    });

    test('vom System gestarteter Sender: Auswahl folgt', () async {
      final c = _Ctx();
      addTearDown(c.dispose);
      c.controller;
      await c.playback.playStation(stationsCatalog[4]);
      await _flush();
      expect(c.active, stationsCatalog[4]);
      expect(c.sink.events, <String>['play {station: radio3fm}']);
    });
  });

  group('Steuerung', () {
    test('Shuffle spielt eine andere Station', () async {
      final c = _Ctx();
      addTearDown(c.dispose);
      final before = c.active;
      await c.controller.shuffleStation();
      expect(c.active, isNot(before));
      expect(c.playback.plays, <String>['play:${c.active.slug}']);
    });

    test('Lautstaerke wird nur mit "Lautstaerke merken" gespeichert', () async {
      final on = _Ctx();
      addTearDown(on.dispose);
      await on.controller.setVolume(0.4);
      expect(on.prefs.readVolume(), 0.4);

      final off = _Ctx(settings: const AppSettings(rememberVolume: false));
      addTearDown(off.dispose);
      await off.controller.setVolume(0.4);
      expect(off.prefs.readVolume(), isNull);
      expect(off.playback.state.volume, 0.4);
    });

    test('Titel geht an Benachrichtigung und Widget', () async {
      final c = _Ctx();
      addTearDown(c.dispose);
      c.controller;
      await _flush();
      expect(c.playback.calls, contains("now:linefm:I Was Lovin' You"));
      expect(c.widget.updates, contains("linefm:I Was Lovin' You:false"));
    });

    test('gewaehlte Station und Wiedergabe steuern den Live-Motor', () async {
      final c = _Ctx();
      addTearDown(c.dispose);
      final repo = c.container.read(nowPlayingRepositoryProvider);
      c.container.read(playerStateProvider);
      await _flush();
      await c.controller.startStation(stationsCatalog[1]);
      await _flush();
      expect((repo as TestRepository).calls, contains('active:linefmrap'));
      expect(repo.calls, contains('playing:true'));
    });
  });

  group('Start', () {
    test(
      'Autoplay spielt die letzte Station, Lautstaerke kommt zurueck',
      () async {
        final c = _Ctx(lastStation: 'linefmlofi', volume: 0.6);
        addTearDown(c.dispose);
        await c.controller.startup(web: false);
        expect(
          c.playback.calls,
          containsAllInOrder(<String>['volume:0.6', 'play:linefmlofi']),
        );
      },
    );

    test('Autoplay aus: nichts startet', () async {
      final c = _Ctx(settings: const AppSettings(autoplay: false));
      addTearDown(c.dispose);
      await c.controller.startup(web: false);
      expect(c.playback.plays, isEmpty);
    });

    test('?station= waehlt den Sender', () async {
      final c = _Ctx(settings: const AppSettings(autoplay: false));
      addTearDown(c.dispose);
      await c.controller.startup(
        launchUri: Uri.parse('https://app.linefm.de/?station=fobfm'),
        web: true,
      );
      expect(c.active.slug, 'fobfm');
    });

    test('Deep Link startet den Sender', () async {
      final c = _Ctx(settings: const AppSettings(autoplay: false));
      addTearDown(c.dispose);
      await c.controller.startup(web: false);
      DeepLinks.dispatch(Uri.parse('linefm://play?station=linefmgaming'));
      await _flush();
      await _flush();
      expect(c.playback.calls, contains('play:linefmgaming'));
    });

    testWidgets('Web: Autoplay erst nach der ersten Nutzeraktion', (
      tester,
    ) async {
      final c = _Ctx();
      addTearDown(c.dispose);
      await c.controller.startup(web: true);
      expect(c.controller.autoplayPending, isTrue);
      expect(c.playback.plays, isEmpty);

      c.controller.onUserInteraction();
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.playback.plays, <String>['play:linefm']);
    });

    testWidgets('Web: eigener Start in der ersten Aktion verhindert Autoplay', (
      tester,
    ) async {
      final c = _Ctx();
      addTearDown(c.dispose);
      await c.controller.startup(web: true);
      c.controller.onUserInteraction();
      await c.controller.startStation(stationsCatalog[2]);
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.playback.plays, <String>['play:linefmgaming']);
    });
  });

  group('Web-Autoplay-Sperre', () {
    test(
      'Start ohne Nutzeraktion: nur Auswahl, Knopf "Radio starten"',
      () async {
        var active = false;
        final c = _Ctx(
          settings: const AppSettings(autoplay: false),
          activation: () => active,
        );
        addTearDown(c.dispose);
        await c.controller.startStation(stationsCatalog[3]);
        expect(c.active, stationsCatalog[3]);
        expect(c.playback.plays, isEmpty);
        expect(c.container.read(autoplayBlockedProvider), isTrue);

        active = true;
        await c.controller.startStation(stationsCatalog[3]);
        await _flush();
        expect(c.playback.plays, <String>['play:${stationsCatalog[3].slug}']);
        expect(c.container.read(autoplayBlockedProvider), isFalse);
      },
    );

    test('Web-Autoplay ohne Nutzeraktion zeigt den Knopf', () async {
      final c = _Ctx(activation: () => false);
      addTearDown(c.dispose);
      await c.controller.startup(web: true);
      expect(c.controller.autoplayPending, isTrue);
      expect(c.container.read(autoplayBlockedProvider), isTrue);
    });

    testWidgets('Wiedergabe von anderer Stelle blendet den Knopf aus', (
      tester,
    ) async {
      final c = _Ctx(activation: () => false);
      addTearDown(c.dispose);
      await c.controller.startup(web: true);
      c.playback.emit(const PlayerUiState(status: PlayerStatus.playing));
      await tester.pump();
      expect(c.container.read(autoplayBlockedProvider), isFalse);
    });

    test('Nativ (Standard): kein Knopf', () async {
      final c = _Ctx();
      addTearDown(c.dispose);
      await c.controller.startup(web: false);
      expect(c.container.read(autoplayBlockedProvider), isFalse);
    });
  });

  group('Cast', () {
    test('Stop im Player beendet die Wiedergabe am Cast-Geraet', () async {
      final cast = _Cast(playing: true);
      final c = _Ctx(settings: const AppSettings(autoplay: false), cast: cast);
      addTearDown(c.dispose);
      await c.controller.togglePlayback();
      expect(cast.stops, 1);
      expect(c.playback.plays, isEmpty);
    });

    test('ohne laufenden Cast-Sender startet Play lokal', () async {
      final cast = _Cast(playing: false);
      final c = _Ctx(settings: const AppSettings(autoplay: false), cast: cast);
      addTearDown(c.dispose);
      await c.controller.togglePlayback();
      expect(cast.stops, 0);
      expect(c.playback.plays, hasLength(1));
    });

    test('Anzeige: Cast-Sender gilt als "spielt"', () {
      final station = stationsCatalog[1];
      const local = PlayerUiState(volume: 0.5);
      final cast = CastState(
        available: true,
        connectedDevice: const CastDevice(id: 'tv', name: 'TV'),
        station: station,
      );
      final merged = mergeCastPlayback(local, cast);
      expect(merged.isPlaying, isTrue);
      expect(merged.station, station);
      expect(merged.volume, 0.5);
      expect(mergeCastPlayback(local, const CastState()), local);
    });
  });
}

class _Cast extends NoopCastService {
  _Cast({required this.playing});

  final bool playing;
  int stops = 0;

  @override
  CastState get state => CastState(
    available: true,
    connectedDevice: const CastDevice(id: 'tv', name: 'TV'),
    station: playing ? stationsCatalog.first : null,
  );

  @override
  Future<void> stopMedia() async => stops++;
}
