import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/data/artwork/cover_disk_cache.dart';
import 'package:linefm_radio/data/live/now_playing_repository.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/schedule_slot.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/history/history_screen.dart';
import 'package:linefm_radio/features/mini_player/mini_player.dart';
import 'package:linefm_radio/ui/widgets/cover_image.dart';
import 'package:material_ui/material_ui.dart';

import '../stations/stations_test_host.dart';

/// laut.fm unreachable: every call fails like a device without network.
class _OfflineApi implements LautApi {
  int calls = 0;

  Future<T> _fail<T>() async {
    calls++;
    throw http.ClientException('offline');
  }

  @override
  Future<Track?> currentSong(String slug) => _fail();

  @override
  Future<List<Track>> lastSongs(String slug) => _fail();

  @override
  Future<int?> listeners(String slug) => _fail();

  @override
  Future<List<ScheduleSlot>> schedule(String slug) => _fail();

  @override
  Future<String?> streamUrl(String slug) => _fail();
}

/// Live data for one station, as laut.fm would answer.
class _OnlineApi implements LautApi {
  _OnlineApi({required this.current, required this.last});

  final Track current;
  final List<Track> last;

  @override
  Future<Track?> currentSong(String slug) async =>
      slug == 'linefm' ? current : null;

  @override
  Future<List<Track>> lastSongs(String slug) async =>
      slug == 'linefm' ? last : const <Track>[];

  @override
  Future<int?> listeners(String slug) async => null;

  @override
  Future<List<ScheduleSlot>> schedule(String slug) async =>
      const <ScheduleSlot>[];

  @override
  Future<String?> streamUrl(String slug) async => null;
}

/// Cover cache that only knows covers stored before the restart.
class _DiskCache implements CoverDiskCache {
  _DiskCache(this.stored);

  final Set<String> stored;
  final List<String> reads = <String>[];

  @override
  Future<Uint8List?> read(String url) async {
    reads.add(url);
    return stored.contains(url) ? Uint8List(0) : null;
  }

  @override
  Future<void> write(String url, Uint8List bytes) async {}

  @override
  Future<void> setMaxBytes(int maxBytes) async {}

  @override
  Future<void> clear() async {}
}

class _OfflineHarness extends Harness {
  _OfflineHarness(this.prefs, this.repo);

  final PrefsStore prefs;
  final NowPlayingRepository repo;

  /// Same as [Harness], with the given storage and live data engine.
  @override
  List<Override> get overrides => <Override>[
    ...super.overrides.skip(2),
    prefsProvider.overrideWithValue(prefs),
    nowPlayingRepositoryProvider.overrideWithValue(repo),
  ];
}

final DateTime _t0 = DateTime(2026, 11, 26, 8);

Track _song(String title, int startMin, {String? cover}) => Track(
  artist: 'Artist',
  title: title,
  artworkUrl: cover,
  startedAt: _t0.add(Duration(minutes: startMin)),
  endsAt: _t0.add(Duration(minutes: startMin + 3)),
);

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// First run online: live data arrives and the repository saves it.
Future<InMemoryPrefsStore> _firstRun() async {
  final prefs = InMemoryPrefsStore();
  await prefs.setStorageConsent(value: true);
  final online = LiveNowPlayingRepository(
    api: _OnlineApi(
      current: _song('Now', 0, cover: 'https://cover/now.jpg'),
      last: <Track>[_song('Before', -3, cover: 'https://cover/before.jpg')],
    ),
    activeStation: stationsCatalog.first,
    readSnapshot: prefs.readLiveCache,
    writeSnapshot: prefs.writeLiveCache,
    // No real timers in tests.
    timer: (_, _) => Timer(Duration.zero, () {}),
    periodicTimer: (_, _) => Timer(Duration.zero, () {}),
  );
  await online.refresh();
  await _settle();
  online.dispose();
  return prefs;
}

void main() {
  tearDown(() => CoverImage.diskCache = null);

  group('LiveNowPlayingRepository device snapshot', () {
    test('round trip: saved state comes back after a restart', () async {
      final prefs = await _firstRun();
      expect(prefs.readLiveCache(), isNotNull);

      final restarted = LiveNowPlayingRepository(
        api: _OfflineApi(),
        foreground: false,
        readSnapshot: prefs.readLiveCache,
      );
      final track = await restarted.watchTrack(stationsCatalog.first).first;
      expect(track?.title, 'Now');
      expect(track?.artworkUrl, 'https://cover/now.jpg');
      expect(track?.lastSeen, isTrue);
      final history = await restarted.watchHistory(stationsCatalog.first).first;
      expect(history.map((e) => e.track.title), <String>['Now', 'Before']);
      expect(history.last.track.artworkUrl, 'https://cover/before.jpg');
      // Restored entries are not live.
      expect(history.first.isLive, isFalse);
      expect(history.every((e) => e.track.lastSeen), isTrue);
      restarted.dispose();
    });

    test('history on the device is bounded to 50 entries', () {
      String? saved;
      final stations = <String, Object?>{
        for (final s in stationsCatalog.take(8))
          s.slug: <String, Object?>{
            'current': _song('${s.slug}-now', 0).toJson(),
            'last': <Object?>[
              for (var i = 1; i <= 10; i++)
                _song('${s.slug}-$i', -3 * i).toJson(),
            ],
          },
      };
      final r = LiveNowPlayingRepository(
        api: _OfflineApi(),
        foreground: false,
        readSnapshot: () =>
            jsonEncode(<String, Object?>{'v': 1, 'stations': stations}),
        writeSnapshot: (json) async => saved = json,
      )..setActiveStation(stationsCatalog[2]);
      expect(saved, isNotNull);
      final data = jsonDecode(saved!) as Map<String, Object?>;
      final stored = (data['stations']! as Map<String, Object?>).values
          .map((v) => ((v! as Map<String, Object?>)['last']! as List).length)
          .fold<int>(0, (a, b) => a + b);
      expect(stored, LiveNowPlayingRepository.maxStoredHistory);
      // The active station comes first and keeps its full history.
      final active =
          (data['stations']! as Map<String, Object?>)[stationsCatalog[2].slug]!
              as Map<String, Object?>;
      expect(active['last']! as List, hasLength(10));
      r.dispose();
    });

    test('live data replaces the restored track', () async {
      final prefs = await _firstRun();
      final r = LiveNowPlayingRepository(
        api: _OnlineApi(
          current: _song('Fresh', 6),
          last: <Track>[_song('Now', 0), _song('Before', -3)],
        ),
        activeStation: stationsCatalog.first,
        readSnapshot: prefs.readLiveCache,
        timer: (_, _) => Timer(Duration.zero, () {}),
        periodicTimer: (_, _) => Timer(Duration.zero, () {}),
      );
      await r.refresh();
      await _settle();
      final track = await r.watchTrack(stationsCatalog.first).first;
      expect(track?.title, 'Fresh');
      expect(track?.lastSeen, isFalse);
      final history = await r.watchHistory(stationsCatalog.first).first;
      expect(history.first.isLive, isTrue);
      expect(history.any((e) => e.track.lastSeen), isFalse);
      // Known covers stay with their songs.
      expect(
        history.firstWhere((e) => e.track.title == 'Before').track.artworkUrl,
        'https://cover/before.jpg',
      );
      r.dispose();
    });

    test('broken snapshot is ignored', () async {
      final r = LiveNowPlayingRepository(
        api: _OfflineApi(),
        foreground: false,
        readSnapshot: () => '{not json',
      );
      expect(await r.watchTrack(stationsCatalog.first).first, isNull);
      r.dispose();
    });
  });

  testWidgets('offline start shows the restored track and history with '
      'cached covers and a last-seen hint', (tester) async {
    final prefs = await tester.runAsync(_firstRun);
    final cache = _DiskCache(<String>{
      'https://cover/now.jpg',
      'https://cover/before.jpg',
    });
    CoverImage.diskCache = cache;
    final api = _OfflineApi();
    final repo = LiveNowPlayingRepository(
      api: api,
      foreground: false,
      activeStation: stationsCatalog.first,
      readSnapshot: prefs!.readLiveCache,
      writeSnapshot: prefs.writeLiveCache,
    );
    final h = _OfflineHarness(prefs, repo);
    addTearDown(h.container.dispose);
    await tester.pumpWidget(
      h.app(
        const Column(
          children: <Widget>[
            Expanded(child: HistoryScreen()),
            MiniPlayer(),
          ],
        ),
      ),
    );
    await settle(tester);

    expect(find.text('Now'), findsWidgets);
    expect(find.text('Before'), findsOneWidget);
    // Visible hint in the mini player and on the top history entry.
    expect(find.text('Zuletzt gesehen'), findsOneWidget);
    expect(find.textContaining('Zuletzt gesehen ·'), findsOneWidget);
    // Screen readers hear it too.
    expect(
      find.bySemanticsLabel(RegExp('Now, Artist, Zuletzt gesehen')),
      findsWidgets,
    );
    // Covers come from the on-device cache, not the station logo.
    expect(cache.reads, contains('https://cover/now.jpg'));
    expect(cache.reads, contains('https://cover/before.jpg'));
    expect(api.calls, 0);
  });

  test('clear storage removes the saved tracks and history', () async {
    final prefs = await _firstRun();
    expect(prefs.readLiveCache(), isNotNull);
    await prefs.clearAll();
    expect(prefs.readLiveCache(), isNull);
    final r = LiveNowPlayingRepository(
      api: _OfflineApi(),
      foreground: false,
      readSnapshot: prefs.readLiveCache,
    );
    expect(await r.watchTrack(stationsCatalog.first).first, isNull);
    expect(await r.watchHistory(stationsCatalog.first).first, isEmpty);
    r.dispose();
  });
}
