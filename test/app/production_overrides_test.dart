import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/data/artwork/itunes_artwork.dart';
import 'package:linefm_radio/data/live/now_playing_repository.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/share/system_share_service.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';

/// Q-01: Die Release-Verdrahtung (`productionOverrides`) laeuft in keinem
/// anderen Test. Hier wird sie mit einem MockClient gebaut und geprueft,
/// dass die echten Dienste aktiv sind und keine Stubs.
void main() {
  late List<Uri> requests;

  ProviderContainer build() {
    requests = <Uri>[];
    final client = MockClient((r) async {
      requests.add(r.url);
      return http.Response('{"results":[]}', 200);
    });
    const config = AppConfig();
    final container = ProviderContainer(
      overrides: productionOverrides(
        config: config,
        prefs: InMemoryPrefsStore(),
        playback: NoopPlaybackService(),
        telemetry: TelemetryHub.noop(config),
        httpClient: client,
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  test('echte Dienste statt Stubs', () {
    final c = build();
    expect(c.read(lautApiProvider), isA<HttpLautApi>());
    expect(c.read(artworkProvider), isA<ItunesArtworkService>());
    expect(
      c.read(nowPlayingRepositoryProvider),
      isA<LiveNowPlayingRepository>(),
    );
    expect(c.read(shareServiceProvider), isA<SystemShareService>());
  });

  test('Cast: ohne gestartetes SDK Noop (L4, Start erst beim Tippen)', () {
    castBackend = null;
    final c = build();
    expect(c.read(castServiceProvider), isA<NoopCastService>());
  });

  test('L5: "Cover laden" aus -> keine Anfrage an Apple', () async {
    final c = build();
    c
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(loadArtwork: false));
    final artwork = c.read(artworkProvider);
    expect(artwork, isA<ApiCoverOnlyArtworkService>());
    expect(await artwork.lookup(const Track(artist: 'A', title: 'B')), isNull);
    final api = await artwork.lookup(
      const Track(artist: 'A', title: 'B', artworkUrl: 'https://x/c.jpg'),
    );
    expect(api!.artworkUrl, 'https://x/c.jpg');
    expect(requests.where((u) => u.host == 'itunes.apple.com'), isEmpty);

    c
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(loadArtwork: true));
    expect(c.read(artworkProvider), isA<ItunesArtworkService>());
  });
}
