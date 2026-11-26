import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:linefm_radio/data/artwork/cover_disk_cache.dart';
import 'package:path_provider/path_provider.dart';

/// Opens the cover cache in `<app cache folder>/covers`. Returns null when
/// the folder is not available; covers then load from the network only.
Future<CoverDiskCache?> openCoverDiskCache() async {
  try {
    final base = await getApplicationCacheDirectory();
    return FileCoverDiskCache(
      Directory('${base.path}${Platform.pathSeparator}covers'),
    );
  } on Object catch (e) {
    debugPrint('Cover cache unavailable: $e');
    return null;
  }
}

/// File based [CoverDiskCache] with a total size limit.
///
/// One file per URL ([coverCacheKey]). A read refreshes the modification
/// time, so eviction removes the least recently used files first until the
/// folder is at or below [maxBytes]. File errors are swallowed: the cache
/// is an optimisation and must never break cover display.
class FileCoverDiskCache implements CoverDiskCache {
  FileCoverDiskCache(this.directory, {this._maxBytes = defaultMaxBytes});

  /// Default of the cache size setting. 40 MB holds a few hundred 600x600 covers (about 60 to 120 KB each).
  static const int defaultMaxBytes = 40 * 1024 * 1024;

  final Directory directory;
  int _maxBytes;

  int get maxBytes => _maxBytes;

  @override
  Future<void> setMaxBytes(int maxBytes) async {
    if (maxBytes <= 0 || maxBytes == _maxBytes) return;
    final lower = maxBytes < _maxBytes;
    _maxBytes = maxBytes;
    if (lower) {
      try {
        await evict();
      } on FileSystemException catch (e) {
        debugPrint('Cover cache not trimmed: $e');
      }
    }
  }

  File _file(String url) => File(
    '${directory.path}${Platform.pathSeparator}${coverCacheKey(url)}.img',
  );

  @override
  Future<Uint8List?> read(String url) async {
    try {
      final file = _file(url);
      if (!file.existsSync()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      try {
        await file.setLastModified(DateTime.now());
      } on FileSystemException {
        // Fixed timestamps only weaken the LRU order.
      }
      return bytes;
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> write(String url, Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxBytes) return;
    try {
      await directory.create(recursive: true);
      final file = _file(url);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      if (file.existsSync()) await file.delete();
      await tmp.rename(file.path);
      await evict();
    } on FileSystemException catch (e) {
      debugPrint('Cover not cached: $e');
    }
  }

  /// Deletes least recently used files until the total is <= [maxBytes].
  Future<void> evict() async {
    if (!directory.existsSync()) return;
    final files = <(File, int, DateTime)>[];
    var total = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final stat = entity.statSync();
      files.add((entity, stat.size, stat.modified));
      total += stat.size;
    }
    if (total <= maxBytes) return;
    files.sort((a, b) => a.$3.compareTo(b.$3));
    for (final (file, size, _) in files) {
      if (total <= maxBytes) break;
      try {
        await file.delete();
        total -= size;
      } on FileSystemException {
        // File in use; try the next one.
      }
    }
  }

  @override
  Future<void> clear() async {
    try {
      if (directory.existsSync()) await directory.delete(recursive: true);
    } on FileSystemException catch (e) {
      debugPrint('Cover cache not cleared: $e');
    }
  }
}
