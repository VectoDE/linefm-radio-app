import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/audio/audio_handler.dart';
import 'package:linefm_radio/services/audio/radio_player.dart';

/// Player ohne Ton.
class _SilentPlayer implements RadioPlayer {
  final StreamController<RadioSignal> _signals =
      StreamController<RadioSignal>.broadcast(sync: true);

  @override
  Stream<RadioSignal> get signals => _signals.stream;

  @override
  Future<void> load(Uri url) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> dispose() => _signals.close();
}

/// laut.fm-API mit fester Antwort fuer stream_url.
class _Api implements LautApi {
  _Api(this.answer);

  final Future<String?> Function() answer;
  int calls = 0;

  @override
  Future<Track?> currentSong(String slug) async => null;

  @override
  Future<List<Track>> lastSongs(String slug) async => const <Track>[];

  @override
  Future<int?> listeners(String slug) async => null;

  @override
  Future<String?> streamUrl(String slug) {
    calls++;
    return answer();
  }
}

void main() {
  final rap = stationBySlug('linefmrap')!;

  Future<(Uri, Uri, _Api)> resolveTwice(
    Future<String?> Function() answer,
  ) async {
    final api = _Api(answer);
    final handler = LinefmAudioHandler(player: _SilentPlayer());
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(InMemoryPrefsStore()),
        playbackServiceProvider.overrideWithValue(handler),
        lautApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.read(playerControllerProvider);
    final first = await handler.streamUrlResolver(rap);
    final second = await handler.streamUrlResolver(rap);
    return (first, second, api);
  }

  group('Stream-URL (PlayerController)', () {
    test('https-URL aus der API wird genommen und gemerkt', () async {
      final (a, b, api) = await resolveTwice(
        () async => 'https://linefmrap.stream.laut.fm/linefmrap',
      );
      expect(a, Uri.parse('https://linefmrap.stream.laut.fm/linefmrap'));
      expect(b, a);
      expect(api.calls, 1, reason: 'zweiter Aufruf aus dem Zwischenspeicher');
    });

    test('ohne Antwort: Rueckfall-URL, kein Merken', () async {
      final (a, _, api) = await resolveTwice(() async => null);
      expect(a, Uri.parse(rap.fallbackStreamUrl));
      expect(api.calls, 2);
    });

    test('http statt https: Rueckfall', () async {
      final (a, _, _) = await resolveTwice(
        () async => 'http://linefmrap.stream.laut.fm/linefmrap',
      );
      expect(a, Uri.parse(rap.fallbackStreamUrl));
    });

    test('Fehler der API: Rueckfall', () async {
      final (a, _, _) = await resolveTwice(() async => throw Exception('x'));
      expect(a, Uri.parse(rap.fallbackStreamUrl));
    });
  });
}
