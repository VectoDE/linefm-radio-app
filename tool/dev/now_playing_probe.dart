// Live-Probe fuer die Datenschicht (nicht ausgeliefert, nur Entwicklung).
//
// Aufruf (laeuft echte Netzwerkanfragen gegen api.laut.fm und iTunes):
//   flutter test tool/dev/now_playing_probe.dart
// Dauer per Umgebungsvariable PROBE_MINUTES (Standard 5). Wie in der App
// ohne WebSocket (WS_ENABLED=false); PROBE_WS=1 schaltet ihn zu Testzwecken
// zu.
//
// `flutter test` statt `dart run`, weil die Domaene dart:ui (Color) nutzt.
// Ohne testWidgets ist kein Test-Binding aktiv, HTTP und WebSocket laufen
// also echt.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/data/api/http_cache.dart';
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/data/api/song_change_socket.dart';
import 'package:linefm_radio/data/artwork/itunes_artwork.dart';
import 'package:linefm_radio/data/live/now_playing_repository.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/stations_config.dart';
import 'package:linefm_radio/domain/track.dart';

void _log(String message) =>
    stdout.writeln('${DateTime.now().toIso8601String()} $message');

String _fmt(Track? t) => t == null
    ? '-'
    : '${t.artist} - ${t.title} '
          '[${t.startedAt?.toIso8601String() ?? '?'} .. '
          '${t.endsAt?.toIso8601String() ?? 'offen'}]'
          '${t.artworkUrl == null ? '' : ' cover'}';

void main() {
  final minutes =
      int.tryParse(Platform.environment['PROBE_MINUTES'] ?? '') ?? 5;

  test('NowPlayingRepository live $minutes min', () async {
    installBundledStations(
      parseStationsConfig(File('config/stations.yaml').readAsStringSync()),
    );
    final cache = HttpCache();
    final api = HttpLautApi(cache: cache);
    final socket = Platform.environment['PROBE_WS'] == '1'
        ? WebSocketSongChangeSocket(guard: TrafficGuard(platformAllowed: true))
        : null;
    final artwork = ItunesArtworkService();
    final repo = LiveNowPlayingRepository(
      api: api,
      socket: socket,
      artwork: artwork,
    );

    final changes = <String, int>{};
    final last = <String, Track?>{};
    final subs = <StreamSubscription<Object?>>[
      ?socket?.states.listen((s) => _log('WS-Zustand: ${s.name}')),
      ?socket?.changes.listen(
        (c) => _log(
          'WS ${c.stationSlug}${c.isLive ? ' (live)' : ''}: ${_fmt(c.track)}',
        ),
      ),
      repo.watchOnline().listen((o) => _log('online: $o')),
      repo.watchStations().listen((list) {
        for (final s in list) {
          final t = s.track;
          final before = last[s.station.slug];
          if (before?.title != t?.title || before?.artist != t?.artist) {
            changes[s.station.slug] = (changes[s.station.slug] ?? 0) + 1;
            _log('Titel ${s.station.slug}: ${_fmt(t)}');
          }
          last[s.station.slug] = t;
        }
      }),
      repo
          .watchTrack(stationsCatalog.first)
          .listen((t) => _log('aktiv linefm: ${_fmt(t)}')),
    ];

    await Future<void>.delayed(Duration(minutes: minutes));

    // Abgleich: Zustand des Repos gegen frische API-Antwort.
    var mismatches = 0;
    for (final s in stationsCatalog) {
      final fresh = await HttpLautApi().currentSong(s.slug);
      final mine = last[s.slug];
      final same = fresh?.title == mine?.title && fresh?.artist == mine?.artist;
      // Erlaubter Versatz: Ticker anderer Sender werden alle 60 s gepollt;
      // die API-Antwort kann ihrerseits aus dem Cache hinterherhinken.
      final freshStart = fresh?.startedAt;
      final mineStart = mine?.startedAt;
      final pollLag =
          freshStart != null &&
          DateTime.now().difference(freshStart) < const Duration(seconds: 75);
      final apiLag =
          freshStart != null &&
          mineStart != null &&
          mineStart.isAfter(freshStart);
      final ok = same || pollLag || apiLag;
      if (!ok) mismatches++;
      _log(
        'Abgleich ${s.slug}: '
        '${same ? 'OK' : (ok ? 'OK (Versatz)' : 'ABWEICHUNG')} '
        'repo=${_fmt(mine)} api=${_fmt(fresh)}',
      );
    }
    _log(
      'Wechsel je Sender (inkl. Erstwert): $changes; '
      'HTTP-Anfragen laut.fm: ${cache.networkRequests}; '
      'iTunes-Anfragen: ${artwork.networkRequests}; '
      'WebSocket: ${socket == null ? 'aus' : '${socket.guard.kbPerMinute.round()} KB/min'}',
    );

    for (final sub in subs) {
      await sub.cancel();
    }
    repo.dispose();
    await artwork.dispose();
    expect(mismatches, 0);
  }, timeout: Timeout(Duration(minutes: minutes + 3)));
}
