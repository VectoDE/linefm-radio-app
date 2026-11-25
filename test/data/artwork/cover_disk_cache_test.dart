import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/data/artwork/cached_cover_image.dart';
import 'package:linefm_radio/data/artwork/cover_disk_cache.dart';
import 'package:linefm_radio/data/artwork/cover_disk_cache_io.dart';

/// 1x1 transparent PNG.
final Uint8List _png = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _MemoryCache implements CoverDiskCache {
  final Map<String, Uint8List> data = <String, Uint8List>{};
  int reads = 0;

  @override
  Future<Uint8List?> read(String url) async {
    reads++;
    return data[url];
  }

  @override
  Future<void> write(String url, Uint8List bytes) async => data[url] = bytes;

  @override
  Future<void> clear() async => data.clear();
}

Future<ui.Codec> _decode(ui.ImmutableBuffer buffer, {dynamic getTargetSize}) =>
    ui.instantiateImageCodecWithSize(buffer);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('coverCacheKey', () {
    test('matches FNV-1a 64 reference values', () {
      expect(coverCacheKey(''), 'cbf29ce484222325');
      expect(coverCacheKey('a'), 'af63dc4c8601ec8c');
    });

    test('differs per URL and is stable', () {
      const a = 'https://is1-ssl.mzstatic.com/a/600x600bb.jpg';
      const b = 'https://is1-ssl.mzstatic.com/b/600x600bb.jpg';
      expect(coverCacheKey(a), coverCacheKey(a));
      expect(coverCacheKey(a), isNot(coverCacheKey(b)));
    });
  });

  group('FileCoverDiskCache', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('covers_test'));
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('write then read returns the bytes; unknown URL is null', () async {
      final cache = FileCoverDiskCache(dir);
      await cache.write('u1', Uint8List.fromList(<int>[1, 2, 3]));
      expect(await cache.read('u1'), <int>[1, 2, 3]);
      expect(await cache.read('u2'), isNull);
    });

    test('evicts least recently used files above the limit', () async {
      final cache = FileCoverDiskCache(dir, maxBytes: 250);
      final chunk = Uint8List(100);
      await cache.write('old', chunk);
      await cache.write('used', chunk);
      // Make "old" clearly the oldest, then touch "used" by reading it.
      File('${dir.path}${Platform.pathSeparator}${coverCacheKey('old')}.img')
          .setLastModifiedSync(DateTime(2020));
      await cache.read('used');
      await cache.write('new', chunk);

      expect(await cache.read('old'), isNull);
      expect(await cache.read('used'), isNotNull);
      expect(await cache.read('new'), isNotNull);
    });

    test('skips entries larger than the limit and empty data', () async {
      final cache = FileCoverDiskCache(dir, maxBytes: 10);
      await cache.write('big', Uint8List(11));
      await cache.write('empty', Uint8List(0));
      expect(await cache.read('big'), isNull);
      expect(await cache.read('empty'), isNull);
    });

    test('clear removes everything', () async {
      final cache = FileCoverDiskCache(dir);
      await cache.write('u', Uint8List.fromList(<int>[1]));
      await cache.clear();
      expect(await cache.read('u'), isNull);
    });
  });

  group('CachedCoverImage', () {
    const url = 'https://is1-ssl.mzstatic.com/x/600x600bb.jpg';

    test('network on miss, then stored and served from disk', () async {
      final cache = _MemoryCache();
      var fetches = 0;
      Future<Uint8List> fetch(Uri uri) async {
        fetches++;
        expect(uri.toString(), url);
        return _png;
      }

      final provider = CachedCoverImage(url, cache: cache, fetch: fetch);
      final first = await provider.load(_decode);
      expect(first.frameCount, 1);
      await Future<void>.delayed(Duration.zero);
      expect(fetches, 1);
      expect(cache.data[url], _png);

      await provider.load(_decode);
      expect(fetches, 1, reason: 'second load must come from disk');
    });

    test('damaged cache file is replaced from the network', () async {
      final cache = _MemoryCache()
        ..data[url] = Uint8List.fromList(<int>[1, 2, 3]);
      var fetches = 0;
      final provider = CachedCoverImage(
        url,
        cache: cache,
        fetch: (_) async {
          fetches++;
          return _png;
        },
      );
      await provider.load(_decode);
      await Future<void>.delayed(Duration.zero);
      expect(fetches, 1);
      expect(cache.data[url], _png);
    });

    test('undecodable network data is not stored', () async {
      final cache = _MemoryCache();
      final provider = CachedCoverImage(
        url,
        cache: cache,
        fetch: (_) async => Uint8List.fromList(<int>[9, 9, 9]),
      );
      await expectLater(provider.load(_decode), throwsA(anything));
      expect(cache.data, isEmpty);
    });

    test('equality by URL keeps the memory ImageCache working', () {
      final cache = _MemoryCache();
      expect(
        CachedCoverImage(url, cache: cache),
        CachedCoverImage(url, cache: _MemoryCache()),
      );
      expect(
        CachedCoverImage(url, cache: cache),
        isNot(CachedCoverImage('$url?2', cache: cache)),
      );
      expect(
        CachedCoverImage(url, cache: cache),
        isA<ImageProvider<CachedCoverImage>>(),
      );
    });
  });
}
