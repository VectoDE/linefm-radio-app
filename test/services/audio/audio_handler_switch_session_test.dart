import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/audio/audio_handler.dart';
import 'package:linefm_radio/services/audio/browse_tree.dart';

import 'audio_handler_helpers.dart';

void main() {
  final main = stationsCatalog.first;
  final rap = stationsCatalog[1];

  test('gestoppt, neuer Sender gewaehlt -> Benachrichtigung zeigt '
      'dessen Titel', () async {
    final player = FakeRadioPlayer();
    final h = handler(player);
    final soon = DateTime.now().add(const Duration(minutes: 3));
    await h.playStation(main);
    await settle();
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
    final h = handler(player);
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
      final h = handler(player);
      await h.playStation(main);
      await settle();
      expect(h.state.status, PlayerStatus.playing);
      final stopsBefore = player.stops;

      await h.playStation(rap);
      await settle();

      expect(player.stops, greaterThan(stopsBefore));
      expect(player.played.last.toString(), rap.fallbackStreamUrl);
      expect(h.state.station, rap);
      expect(h.state.status, PlayerStatus.playing);
    });

    test('switch while the old stream is still loading: the old stream '
        'never starts', () async {
      final player = FakeRadioPlayer();
      final h = handler(player);
      final slow = Uri.parse(main.fallbackStreamUrl);
      player.loadGates[slow] = Completer<void>();

      unawaited(h.playStation(main));
      await settle(5);
      await h.playStation(rap);
      // The slow load of the first station finishes after the switch.
      player.loadGates[slow]!.complete();
      await settle();

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
      final h = handler(player)
        ..streamUrlResolver = (station) {
          final c = Completer<Uri>();
          gates[station.slug] = c;
          return c.future;
        };
      final third = stationsCatalog[2];

      unawaited(h.playStation(main));
      unawaited(h.playStation(rap));
      unawaited(h.playStation(third));
      await settle(5);
      // The first lookup was already running; superseded switches may skip
      // theirs. Lookups resolve in reverse order (worst case).
      expect(gates, contains(main.slug));
      gates[third.slug]!.complete(Uri.parse(third.fallbackStreamUrl));
      await settle(5);
      gates[rap.slug]?.complete(Uri.parse(rap.fallbackStreamUrl));
      gates[main.slug]?.complete(Uri.parse(main.fallbackStreamUrl));
      await settle();

      expect(player.played.map((u) => u.toString()), <String>[
        third.fallbackStreamUrl,
      ]);
      expect(h.state.station, third);
      expect(h.state.status, PlayerStatus.playing);
    });

    test('stop during a slow load: nothing starts afterwards', () async {
      final player = FakeRadioPlayer();
      final h = handler(player);
      final slow = Uri.parse(main.fallbackStreamUrl);
      player.loadGates[slow] = Completer<void>();

      unawaited(h.playStation(main));
      await settle(5);
      await h.stopPlayback();
      player.loadGates[slow]!.complete();
      await settle();

      expect(player.played, isEmpty);
      expect(h.state.status, PlayerStatus.idle);
    });
  });

  group('car display error text', () {
    test('is the localized stream error, not the exception', () {
      expect(
        LinefmAudioHandler.userErrorMessage('de'),
        'Stream konnte nicht gestartet werden.',
      );
      expect(
        LinefmAudioHandler.userErrorMessage('en'),
        'Couldn’t start the stream.',
      );
    });
  });

  group('Android Auto session', () {
    test('browsing, prepare and lookups never start playback', () async {
      final player = FakeRadioPlayer();
      final h = handler(player);
      h.subscribeToChildren(BrowseTree.rootId);
      final root = await h.getChildren(BrowseTree.rootId);
      expect(root, isNotEmpty);
      for (final folder in root.where((i) => i.playable != true)) {
        await h.getChildren(folder.id);
      }
      await h.getChildren(BrowseTree.stationsId);
      await h.prepare();
      await h.prepareFromMediaId(main.slug);
      await h.prepareFromSearch(main.displayName);
      await h.getMediaItem(main.slug);
      await h.search(main.displayName);
      await settle();
      expect(player.opened, isEmpty);
      expect(player.played, isEmpty);
      expect(h.state.status, PlayerStatus.idle);
      expect(h.playbackState.value.playing, isFalse);
    });

    test('stations folder lists every station as playable', () async {
      final h = handler(FakeRadioPlayer());
      final items = await h.getChildren(BrowseTree.stationsId);
      expect(items.map((i) => i.id), stationsCatalog.map((s) => s.slug));
      expect(items.every((i) => i.playable == true), isTrue);
    });

    test('playFromMediaId plays the chosen station', () async {
      final player = FakeRadioPlayer();
      final h = handler(player);
      await h.playFromMediaId(rap.slug);
      await settle();
      expect(h.state.station, rap);
      expect(h.state.status, PlayerStatus.playing);
      expect(h.mediaItem.value?.id, rap.slug);
    });

    test(
      'search finds a station by name and playFromSearch plays it',
      () async {
        final player = FakeRadioPlayer();
        final h = handler(player);
        final hits = await h.search(rap.displayName);
        expect(hits.map((i) => i.id), contains(rap.slug));
        await h.playFromSearch(rap.displayName);
        await settle();
        expect(h.state.station, rap);
      },
    );

    test('search without a match returns an empty list', () async {
      final h = handler(FakeRadioPlayer());
      expect(await h.search('zzzz-no-such-station'), isEmpty);
    });

    test(
      'a failed stream shows the localized text, not the exception',
      () async {
        final player = FakeRadioPlayer()..failOpen = true;
        final h = handler(player);
        await h.playStation(main);
        await settle();
        final state = h.playbackState.value;
        expect(state.processingState, AudioProcessingState.error);
        expect(state.errorMessage, LinefmAudioHandler.userErrorMessage());
        expect(state.errorMessage, isNot(contains('open failed')));
        expect(state.errorMessage, isNot(contains('Exception')));
      },
    );
  });
}
