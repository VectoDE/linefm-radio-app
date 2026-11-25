import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/audio/audio_handler.dart';
import 'package:linefm_radio/services/audio/browse_tree.dart';
import 'package:linefm_radio/services/audio/radio_player.dart';
import 'package:linefm_radio/services/audio/reconnect_policy.dart';

class FakeRadioPlayer implements RadioPlayer {
  final StreamController<RadioSignal> _signals =
      StreamController<RadioSignal>.broadcast(sync: true);
  final List<Uri> opened = <Uri>[];
  int stops = 0;
  double? volume;
  bool failOpen = false;

  /// Meldet nach play() automatisch "playing".
  bool autoPlay = true;

  /// Streams that actually started (what the user hears).
  final List<Uri> played = <Uri>[];
  Uri? _loaded;

  /// When set, load() waits for this completer (slow network).
  final Map<Uri, Completer<void>> loadGates = <Uri, Completer<void>>{};

  @override
  Stream<RadioSignal> get signals => _signals.stream;

  void emit(RadioSignal s) => _signals.add(s);

  @override
  Future<void> load(Uri url) async {
    opened.add(url);
    _loaded = url;
    final gate = loadGates[url];
    if (gate != null) await gate.future;
    if (failOpen) throw Exception('open failed');
  }

  @override
  Future<void> play() async {
    played.add(_loaded!);
    if (autoPlay) {
      emit(RadioSignal.buffering);
      emit(RadioSignal.playing);
    }
  }

  @override
  Future<void> stop() async {
    stops++;
    _loaded = null;
    emit(RadioSignal.idle);
  }

  @override
  Future<void> setVolume(double v) async => volume = v;

  @override
  Future<void> dispose() => _signals.close();
}

const _ms = Duration(milliseconds: 1);

LinefmAudioHandler _handler(
  FakeRadioPlayer player, {
  Duration minConnect = Duration.zero,
}) => LinefmAudioHandler(
  player: player,
  minConnectDuration: minConnect,
  connectTimeout: const Duration(milliseconds: 200),
  reconnectPolicy: const ReconnectPolicy(
    delays: <Duration>[_ms, _ms, _ms, _ms, _ms],
  ),
);

Future<void> _settle([int ms = 20]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  final main = stationsCatalog.first;
  final rap = stationsCatalog[1];

  test('playStation verbindet und meldet playing', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player);
    final states = <PlayerStatus>[];
    h.stateStream.listen((s) => states.add(s.status));

    await h.playStation(main);
    await _settle();

    expect(player.opened.single.toString(), main.fallbackStreamUrl);
    expect(states, <PlayerStatus>[
      PlayerStatus.connecting,
      PlayerStatus.playing,
    ]);
    expect(h.state.station, main);
    expect(h.playbackState.value.playing, isTrue);
    expect(h.playbackState.value.processingState, AudioProcessingState.ready);
    expect(h.mediaItem.value?.id, main.slug);
  });

  test('Verbinden dauert mindestens minConnectDuration', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player, minConnect: const Duration(milliseconds: 150));
    await h.playStation(main);
    await _settle(50);
    expect(h.state.status, PlayerStatus.connecting);
    await _settle(200);
    expect(h.state.status, PlayerStatus.playing);
  });

  test('erster Verbindungsfehler fuehrt direkt zu error', () async {
    final player = FakeRadioPlayer()..failOpen = true;
    final h = _handler(player);
    await h.playStation(main);
    await _settle();
    expect(h.state.status, PlayerStatus.error);
    expect(h.playbackState.value.processingState, AudioProcessingState.error);
    expect(player.opened, hasLength(1));
  });

  test('Timeout beim Verbinden fuehrt zu error', () async {
    final player = FakeRadioPlayer()..autoPlay = false;
    final h = _handler(player);
    await h.playStation(main);
    await _settle(300);
    expect(h.state.status, PlayerStatus.error);
  });

  test('Netzabbruch: Neuverbindung und zurueck zu playing', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player);
    await h.playStation(main);
    await _settle();
    player.emit(RadioSignal.error);
    expect(h.state.status, PlayerStatus.reconnecting);
    expect(h.playbackState.value.playing, isTrue);
    await _settle();
    expect(player.opened, hasLength(2));
    expect(h.state.status, PlayerStatus.playing);
  });

  test('nach 5 gescheiterten Neuverbindungen: error', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player);
    await h.playStation(main);
    await _settle();
    player.failOpen = true;
    player.emit(RadioSignal.ended);
    await _settle(100);
    expect(player.opened, hasLength(1 + 5));
    expect(h.state.status, PlayerStatus.error);
  });

  test('Stop gibt den Stream frei und verhindert Neuverbindung', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player);
    await h.playStation(main);
    await _settle();
    await h.stop();
    player.emit(RadioSignal.error);
    await _settle();
    expect(h.state.status, PlayerStatus.idle);
    expect(player.opened, hasLength(1));
    expect(h.playbackState.value.playing, isFalse);
    expect(h.playbackState.value.processingState, AudioProcessingState.idle);
  });

  test('pause (Kopfhoerer/Benachrichtigung) stoppt Live-Radio', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player);
    await h.playStation(main);
    await _settle();
    await h.pause();
    expect(h.state.status, PlayerStatus.idle);
    expect(player.stops, greaterThan(0));
  });

  test('play ohne Auswahl nutzt die zuletzt gemeldete Station', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player)..recentStation = rap;
    await h.play();
    await _settle();
    expect(h.state.station, rap);
  });

  test('Lautstaerke wird begrenzt und beim Ducking abgesenkt', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player);
    await h.setVolume(1.5);
    expect(h.state.volume, 1.0);
    await h.setVolume(0.5);
    expect(player.volume, 0.5);
    h.debugInterrupt(begin: true, duck: true);
    await _settle();
    expect(player.volume, closeTo(0.15, 1e-9));
    h.debugInterrupt(begin: false, duck: true);
    await _settle();
    expect(player.volume, 0.5);
  });

  test('Unterbrechung (Anruf) stoppt und setzt danach fort', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player);
    await h.playStation(rap);
    await _settle();
    h.debugInterrupt(begin: true);
    await _settle();
    expect(h.state.status, PlayerStatus.idle);
    h.debugInterrupt(begin: false);
    await _settle();
    expect(h.state.status, PlayerStatus.playing);
    expect(h.state.station, rap);
    expect(player.opened, hasLength(2));
  });

  test('skipToNext/Previous wechseln zyklisch durch die Sender', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player);
    await h.playStation(stationsCatalog.last);
    await h.skipToNext();
    expect(h.state.station, stationsCatalog.first);
    await h.skipToPrevious();
    expect(h.state.station, stationsCatalog.last);
  });

  test('Android Auto: Browse-Tree, playFromMediaId, Suche', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player);

    // Immer drei Ordner, ohne Daten sind zwei davon leer.
    final root = await h.getChildren(AudioService.browsableRootId);
    expect(root.map((e) => e.id), <String>[
      BrowseTree.favoriteStationsId,
      BrowseTree.stationsId,
      BrowseTree.recentId,
    ]);
    expect(root.every((e) => e.playable == false), isTrue);
    expect(await h.getChildren(BrowseTree.favoriteStationsId), isEmpty);
    expect(await h.getChildren(BrowseTree.recentId), isEmpty);

    final stations = await h.getChildren(BrowseTree.stationsId);
    expect(stations, hasLength(6));
    expect(stations.every((e) => e.playable ?? false), isTrue);

    await h.playFromMediaId('linefmlofi');
    await _settle();
    expect(h.state.station?.slug, 'linefmlofi');

    final recent = await h.getChildren(BrowseTree.recentId);
    expect(recent.single.id, 'linefmlofi');

    final hits = await h.search('gaming');
    expect(hits.single.id, 'linefmgaming');

    await h.playFromSearch('LineFM Rap');
    await _settle();
    expect(h.state.station?.slug, 'linefmrap');
  });

  test(
    'updateNowPlaying aktualisiert das MediaItem der aktiven Station',
    () async {
      final player = FakeRadioPlayer();
      final h = _handler(player);
      await h.playStation(main);
      await h.updateNowPlaying(
        main,
        const Track(
          artist: 'Artist',
          title: 'Song',
          artworkUrl: 'https://example.org/a.jpg',
        ),
      );
      expect(h.mediaItem.value?.title, 'Song');
      expect(h.mediaItem.value?.artist, 'Artist');
      expect(h.mediaItem.value?.album, main.displayName);
      expect(h.mediaItem.value?.artUri.toString(), 'https://example.org/a.jpg');

      // Titel einer anderen Station aendert das MediaItem nicht.
      await h.updateNowPlaying(rap, const Track(artist: 'X', title: 'Y'));
      expect(h.mediaItem.value?.title, 'Song');
    },
  );

  test('MPRIS-Lautstaerke (dbusVolume) setzt die Lautstaerke', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player);
    await h.customAction('dbusVolume', <String, dynamic>{'value': 0.3});
    expect(h.state.volume, 0.3);
  });

  test('ReconnectPolicy: 2/4/8/16/30 s, danach null', () {
    const p = ReconnectPolicy();
    expect(
      <int?>[for (var i = 0; i < 6; i++) p.delayFor(i)?.inSeconds],
      <int?>[2, 4, 8, 16, 30, null],
    );
  });

  test('gestoppt, neuer Sender gewaehlt -> Benachrichtigung zeigt '
      'dessen Titel', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player);
    final soon = DateTime.now().add(const Duration(minutes: 3));
    await h.playStation(main);
    await _settle();
    await h.updateNowPlaying(
      main,
      Track(artist: 'Alt', title: 'Alter Sender', endsAt: soon),
    );
    await h.stopPlayback();
    // Die App meldet zuerst die Auswahl, dann deren Titel.
    h.recentStation = rap;
    await h.updateNowPlaying(
      rap,
      Track(artist: 'Neu', title: 'Neuer Sender', endsAt: soon),
    );
    expect(h.mediaItem.value?.title, 'Neuer Sender');
  });

  test('Wechsel per Medientaste zeigt keinen abgelaufenen Titel', () async {
    final player = FakeRadioPlayer();
    final h = _handler(player);
    await h.updateNowPlaying(
      rap,
      Track(
        artist: 'Alt',
        title: 'Laengst vorbei',
        endsAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    );
    await h.playStation(main);
    await h.skipToNext();
    expect(h.state.station, rap);
    expect(h.mediaItem.value?.title, isNot('Laengst vorbei'));
  });

  group('station switch', () {
    test('switch while playing stops the old stream before the new one '
        'starts', () async {
      final player = FakeRadioPlayer();
      final h = _handler(player);
      await h.playStation(main);
      await _settle();
      expect(h.state.status, PlayerStatus.playing);
      final stopsBefore = player.stops;

      await h.playStation(rap);
      await _settle();

      expect(player.stops, greaterThan(stopsBefore));
      expect(player.played.last.toString(), rap.fallbackStreamUrl);
      expect(h.state.station, rap);
      expect(h.state.status, PlayerStatus.playing);
    });

    test('switch while the old stream is still loading: the old stream '
        'never starts', () async {
      final player = FakeRadioPlayer();
      final h = _handler(player);
      final slow = Uri.parse(main.fallbackStreamUrl);
      player.loadGates[slow] = Completer<void>();

      unawaited(h.playStation(main));
      await _settle(5);
      await h.playStation(rap);
      // The slow load of the first station finishes after the switch.
      player.loadGates[slow]!.complete();
      await _settle();

      expect(player.played.map((u) => u.toString()), <String>[
        rap.fallbackStreamUrl,
      ]);
      expect(h.state.station, rap);
      expect(h.state.status, PlayerStatus.playing);
    });

    test('rapid double switch with slow URL lookups: only the last '
        'station plays', () async {
      final player = FakeRadioPlayer();
      final gates = <String, Completer<Uri>>{};
      final h = _handler(player)
        ..streamUrlResolver = (station) {
          final c = Completer<Uri>();
          gates[station.slug] = c;
          return c.future;
        };
      final third = stationsCatalog[2];

      unawaited(h.playStation(main));
      unawaited(h.playStation(rap));
      unawaited(h.playStation(third));
      await _settle(5);
      // The first lookup was already running; superseded switches may skip
      // theirs. Lookups resolve in reverse order (worst case).
      expect(gates, contains(main.slug));
      gates[third.slug]!.complete(Uri.parse(third.fallbackStreamUrl));
      await _settle(5);
      gates[rap.slug]?.complete(Uri.parse(rap.fallbackStreamUrl));
      gates[main.slug]?.complete(Uri.parse(main.fallbackStreamUrl));
      await _settle();

      expect(player.played.map((u) => u.toString()), <String>[
        third.fallbackStreamUrl,
      ]);
      expect(h.state.station, third);
      expect(h.state.status, PlayerStatus.playing);
    });

    test('stop during a slow load: nothing starts afterwards', () async {
      final player = FakeRadioPlayer();
      final h = _handler(player);
      final slow = Uri.parse(main.fallbackStreamUrl);
      player.loadGates[slow] = Completer<void>();

      unawaited(h.playStation(main));
      await _settle(5);
      await h.stopPlayback();
      player.loadGates[slow]!.complete();
      await _settle();

      expect(player.played, isEmpty);
      expect(h.state.status, PlayerStatus.idle);
    });
  });
}
