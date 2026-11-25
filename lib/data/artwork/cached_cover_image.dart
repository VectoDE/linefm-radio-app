import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:linefm_radio/data/artwork/cover_disk_cache.dart';

/// Loads cover bytes from the network. Replaceable in tests.
typedef CoverFetcher = Future<Uint8List> Function(Uri uri);

/// [ImageProvider] for covers: disk cache first, then the network; bytes
/// that decode go into the disk cache. The only request is the cover URL
/// itself, the same one a plain network image would make.
///
/// Equality is by [url], so Flutter's in-memory [ImageCache] still
/// deduplicates decoded images across widgets.
@immutable
class CachedCoverImage extends ImageProvider<CachedCoverImage> {
  const CachedCoverImage(this.url, {required this.cache, this.fetch});

  final String url;
  final CoverDiskCache cache;

  /// Null uses [defaultCoverFetcher].
  final CoverFetcher? fetch;

  @override
  Future<CachedCoverImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<CachedCoverImage>(this);

  @override
  ImageStreamCompleter loadImage(
    CachedCoverImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: load(decode),
    scale: 1,
    debugLabel: url,
  );

  /// Resolves the codec (visible for tests).
  @visibleForTesting
  Future<ui.Codec> load(ImageDecoderCallback decode) async {
    final cached = await cache.read(url);
    if (cached != null) {
      try {
        return await decode(await ui.ImmutableBuffer.fromUint8List(cached));
      } on Object {
        // Damaged file: fall through and load once more from the network.
      }
    }
    final bytes = await (fetch ?? defaultCoverFetcher)(Uri.parse(url));
    if (bytes.isEmpty) throw StateError('Empty cover: $url');
    final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    // Only bytes that decoded are stored, so broken data is never cached.
    unawaited(cache.write(url, bytes));
    return codec;
  }

  @override
  bool operator ==(Object other) =>
      other is CachedCoverImage && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'CachedCoverImage("$url")';
}

/// GET with a 15 s timeout; only HTTP 200 with a body counts.
Future<Uint8List> defaultCoverFetcher(Uri uri) async {
  final response = await http.get(uri).timeout(const Duration(seconds: 15));
  if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
    throw http.ClientException('Cover HTTP ${response.statusCode}', uri);
  }
  return response.bodyBytes;
}
