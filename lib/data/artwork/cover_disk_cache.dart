import 'dart:typed_data';

export 'package:linefm_radio/data/artwork/cover_disk_cache_stub.dart'
    if (dart.library.io) 'package:linefm_radio/data/artwork/cover_disk_cache_io.dart';

/// On-device store for cover image bytes, keyed by image URL.
///
/// Native platforms keep the files in the app cache folder with a size
/// limit (least recently used files go first). Web has no implementation:
/// the browser HTTP cache already keeps the images there.
abstract interface class CoverDiskCache {
  /// Cached bytes for [url], or null when not stored.
  Future<Uint8List?> read(String url);

  /// Stores [bytes] for [url] and evicts old entries above the limit.
  Future<void> write(String url, Uint8List bytes);

  /// Changes the size limit; a lower limit evicts at once.
  Future<void> setMaxBytes(int maxBytes);

  /// Removes every stored cover (part of "clear storage").
  Future<void> clear();
}

/// Stable file name for [url]: 64-bit FNV-1a as hex. Not a security hash;
/// it only spreads URLs over file names without a crypto dependency.
/// Computed on two 32-bit halves so it gives the same result on every
/// platform.
String coverCacheKey(String url) {
  // FNV-1a 64 offset basis 0xcbf29ce484222325, prime 0x100000001b3.
  var hi = 0xcbf29ce4;
  var lo = 0x84222325;
  for (final unit in url.codeUnits) {
    lo ^= unit;
    // (hi:lo) * (0x100:0x000001b3), modulo 2^64.
    final loMul = lo * 0x1b3;
    final carry = loMul ~/ 0x100000000;
    final newLo = loMul % 0x100000000;
    final newHi = (hi * 0x1b3 + lo * 0x100 + carry) % 0x100000000;
    hi = newHi;
    lo = newLo;
  }
  return hi.toRadixString(16).padLeft(8, '0') +
      lo.toRadixString(16).padLeft(8, '0');
}
