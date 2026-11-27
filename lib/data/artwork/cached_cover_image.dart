import 'dart:async';
import 'dart:typed_data';
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

/// Largest cover response accepted (bytes). Covers are about 100 KB; the
/// cap stops a misbehaving server from filling memory.
const int coverMaxBytes = 5 * 1024 * 1024;

/// GET with a 15 s timeout; only HTTP 200 with a body counts. The body is
/// streamed and the download aborted as soon as it exceeds [maxBytes].
Future<Uint8List> defaultCoverFetcher(
  Uri uri, {
  http.Client? client,
  int maxBytes = coverMaxBytes,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final c = client ?? http.Client();
  try {
    return await _fetchCapped(c, uri, maxBytes).timeout(timeout);
  } finally {
    if (client == null) c.close();
  }
}

Future<Uint8List> _fetchCapped(
  http.Client client,
  Uri uri,
  int maxBytes,
) async {
  final response = await client.send(http.Request('GET', uri));
  if (response.statusCode != 200) {
    throw http.ClientException('Cover HTTP ${response.statusCode}', uri);
  }
  final declared = response.contentLength;
  if (declared != null && declared > maxBytes) {
    throw http.ClientException('Cover too large ($declared bytes)', uri);
  }
  final builder = BytesBuilder(copy: false);
  await for (final chunk in response.stream) {
    builder.add(chunk);
    if (builder.length > maxBytes) {
      throw http.ClientException('Cover too large (> $maxBytes bytes)', uri);
    }
  }
  if (builder.isEmpty) {
    throw http.ClientException('Cover HTTP 200 without body', uri);
  }
  return builder.takeBytes();
}
