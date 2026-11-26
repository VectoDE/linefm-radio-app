// Self-host fallback fonts for Flutter Web (L14).
//
// The web engine loads missing characters (emoji, Cyrillic, CJK, symbols) as
// Noto fonts, from `fontFallbackBaseUrl + <path>`. Without our own
// files under assets/fonts/fallback/ such characters appear as boxes.
// This tool places exactly the files that the engine requests.
//
// Invocations:
//   dart run tool/fetch_font_fallback.dart build/web [options]
//       Downloads the files from the lock file (path, SHA-256, size), verifies
//       every checksum and places them under build/web/assets/fonts/fallback/.
//   dart run tool/fetch_font_fallback.dart --update-lock [--sdk-data <file>]
//       Reads the list from the Flutter SDK (font_fallback_data.dart), downloads
//       everything fresh from the network (no cache, S3-05) and rewrites the
//       lock file (after every Flutter update).
//   dart run tool/fetch_font_fallback.dart --check-sdk [--sdk-data <file>]
//       Compares the lock file and the SDK list; exit 1 on mismatch.
//
// Options:
//   --lock <file>         default: tool/font_fallback.lock.json
//   --groups <list>       core,cjk (default: both) or core
//   --cache <folder>      default: .dart_tool/font_fallback_cache
//   --source <url>        default: https://fonts.gstatic.com/s/
//   --sdk-data <file>     default: derived from the running Flutter SDK
//   --license <file>      OFL text (default: assets/fonts/OFL.txt), ends up next to it as OFL.txt.
//                         If the file is missing, the call aborts with exit 1 (R3-P07).
//   --strict              a mismatch between lock file and SDK is an error
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'web_postbuild.dart' show sha256Hex;

const String defaultSource = 'https://fonts.gstatic.com/s/';
const String defaultLock = 'tool/font_fallback.lock.json';
const String fallbackSubdir = 'assets/fonts/fallback';

/// Roboto is the engine's default font and comes through the same base URL
/// (skwasm/skwasm_impl/font_collection.dart and canvaskit/fonts.dart).
final RegExp _robotoPattern = RegExp(r"fontFallbackBaseUrl\}(roboto/[^']+)'");

/// Families whose files are large and only needed for CJK text.
const List<String> cjkPrefixes = <String>[
  'notosanssc/',
  'notosanstc/',
  'notosanshk/',
  'notosansjp/',
  'notosanskr/',
];

class FallbackFont {
  const FallbackFont(this.name, this.path, {this.sha256, this.bytes});
  final String name;
  final String path;
  final String? sha256;
  final int? bytes;

  String get group => groupOf(path);

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'path': path,
    'group': group,
    'sha256': sha256,
    'bytes': bytes,
  };
}

class FontFallbackException implements Exception {
  FontFallbackException(this.message);
  final String message;
  @override
  String toString() => 'fetch_font_fallback: $message';
}

/// Group of a path: `cjk` for the large CJK families, otherwise `core`.
String groupOf(String path) =>
    cjkPrefixes.any(path.startsWith) ? 'cjk' : 'core';

/// Reads all `NotoFont('<name>', '<path>', ...)` from font_fallback_data.dart.
List<FallbackFont> parseFallbackFontData(String source) {
  final pattern = RegExp(r"NotoFont\(\s*'([^']+)',\s*'([^']+)'");
  final seen = <String>{};
  final out = <FallbackFont>[];
  for (final m in pattern.allMatches(source)) {
    final path = m.group(2)!;
    if (seen.add(path)) {
      out.add(FallbackFont(m.group(1)!, path));
    }
  }
  return out;
}

/// Reads the Roboto path from fonts.dart or font_collection.dart.
String? parseRobotoPath(String source) =>
    _robotoPattern.firstMatch(source)?.group(1);

/// License file for the fallback folder: own copyright header, followed by the
/// OFL text from "This Font Software is licensed ..." in the template.
String renderLicense(String oflTemplate) {
  final start = oflTemplate.indexOf('This Font Software is licensed');
  final body = start >= 0 ? oflTemplate.substring(start) : oflTemplate;
  return 'Noto fonts: Copyright The Noto Project Authors (https://github.com/notofonts)\n'
      'Noto Color Emoji: Copyright Google LLC (https://github.com/googlefonts/noto-emoji)\n'
      'Roboto: Copyright 2011 The Roboto Project Authors (https://github.com/googlefonts/roboto-classic)\n'
      'Quelle: Google Fonts, Liste und Pruefsummen in tool/font_fallback.lock.json\n\n'
      '$body';
}

/// Checks that a path stays relative and does not leave its folder.
bool isSafeRelativePath(String path) {
  if (path.isEmpty || path.startsWith('/') || path.contains('\\')) {
    return false;
  }
  if (path.contains(':')) {
    return false;
  }
  return path.split('/').every((s) => s.isNotEmpty && s != '.' && s != '..');
}

/// Reads the lock file.
({String engineRevision, String source, List<FallbackFont> fonts}) parseLock(
  String text,
) {
  final json = jsonDecode(text) as Map<String, dynamic>;
  final fonts = <FallbackFont>[
    for (final e
        in (json['fonts'] as List<dynamic>).cast<Map<String, dynamic>>())
      FallbackFont(
        e['name'] as String,
        e['path'] as String,
        sha256: e['sha256'] as String?,
        bytes: e['bytes'] as int?,
      ),
  ];
  for (final f in fonts) {
    if (!isSafeRelativePath(f.path)) {
      throw FontFallbackException('invalid path in the lock file: ${f.path}');
    }
    if (f.sha256 == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(f.sha256!)) {
      throw FontFallbackException('checksum missing for ${f.path}');
    }
  }
  return (
    engineRevision: json['engineRevision'] as String? ?? '',
    source: json['source'] as String? ?? defaultSource,
    fonts: fonts,
  );
}

/// Writes the lock file (stably sorted so that diffs stay readable).
String encodeLock({
  required String engineRevision,
  required String source,
  required List<FallbackFont> fonts,
}) {
  final sorted = fonts.toList()..sort((a, b) => a.path.compareTo(b.path));
  int sum(String g) =>
      sorted.where((f) => f.group == g).fold(0, (s, f) => s + (f.bytes ?? 0));
  return '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'comment': 'Generated with dart run tool/fetch_font_fallback.dart --update-lock. '
        'Noto fonts and Roboto: SIL Open Font License 1.1 (docs/LIZENZEN-DRITTE.md).',
    'engineRevision': engineRevision,
    'source': source,
    'totals': <String, int>{'core': sum('core'), 'cjk': sum('cjk'), 'files': sorted.length},
    'fonts': [for (final f in sorted) f.toJson()],
  })}\n';
}

/// Differences between two path lists (only in the SDK, only in the lock file).
({List<String> onlySdk, List<String> onlyLock}) diffPaths(
  Iterable<String> sdk,
  Iterable<String> lock,
) {
  final s = sdk.toSet();
  final l = lock.toSet();
  return (
    onlySdk: (s.difference(l).toList()..sort()),
    onlyLock: (l.difference(s).toList()..sort()),
  );
}

// ---------------------------------------------------------------------------
// SDK and network
// ---------------------------------------------------------------------------

/// Flutter root: FLUTTER_ROOT or derived from the running Dart
/// (`<flutter>/bin/cache/dart-sdk/bin/dart`).
Directory? _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty && Directory(env).existsSync()) {
    return Directory(env);
  }
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 4; i++) {
    dir = dir.parent;
  }
  return File('${dir.path}/bin/internal/engine.version').existsSync()
      ? dir
      : null;
}

({List<FallbackFont> fonts, String engineRevision}) readSdk(String? dataPath) {
  final root = _flutterRoot();
  final engineDir = dataPath != null
      ? File(dataPath).parent
      : Directory('${root?.path}/bin/cache/flutter_web_sdk/lib/_engine/engine');
  final data = File(dataPath ?? '${engineDir.path}/font_fallback_data.dart');
  if (!data.existsSync()) {
    throw FontFallbackException(
      '${data.path} not found (run flutter precache --web or pass --sdk-data)',
    );
  }
  final fonts = parseFallbackFontData(data.readAsStringSync());
  for (final candidate in <String>[
    '${engineDir.path}/skwasm/skwasm_impl/font_collection.dart',
    '${engineDir.path}/canvaskit/fonts.dart',
  ]) {
    final f = File(candidate);
    final roboto = f.existsSync()
        ? parseRobotoPath(f.readAsStringSync())
        : null;
    if (roboto != null) {
      fonts.insert(0, FallbackFont('Roboto', roboto));
      break;
    }
  }
  final versionFile = File('${root?.path}/bin/internal/engine.version');
  final rev = versionFile.existsSync()
      ? versionFile.readAsStringSync().trim()
      : '';
  return (fonts: fonts, engineRevision: rev);
}

Future<List<int>> _download(HttpClient client, Uri url) async {
  Object? last;
  for (var attempt = 1; attempt <= 3; attempt++) {
    try {
      final req = await client.getUrl(url);
      final res = await req.close();
      if (res.statusCode == 200) {
        final builder = BytesBuilder(copy: false);
        await res.forEach(builder.add);
        return builder.takeBytes();
      }
      await res.drain<void>();
      last = 'HTTP ${res.statusCode}';
      if (res.statusCode >= 400 && res.statusCode < 500) {
        break;
      }
    } on Object catch (e) {
      last = e;
    }
    await Future<void>.delayed(Duration(seconds: attempt));
  }
  throw FontFallbackException('Download failed: $url ($last)');
}

/// Runs [task] for all entries with limited parallelism.
Future<void> _pool<T>(
  List<T> items,
  int parallel,
  Future<void> Function(T) task,
) async {
  var next = 0;
  Future<void> worker() async {
    while (next < items.length) {
      await task(items[next++]);
    }
  }

  await Future.wait(List.generate(parallel, (_) => worker()));
}

/// Fetches a file (cache or network) and verifies the checksum.
///
/// With [useCache] = false it always loads from the network (for --update-lock:
/// without a known checksum, old or foreign cache content must not end up in
/// the lock file). The result still lands in the cache.
Future<List<int>> fetchVerified(
  HttpClient client,
  FallbackFont font, {
  required String source,
  required Directory cache,
  bool useCache = true,
}) async {
  final cached = File('${cache.path}/${font.path}');
  if (useCache && cached.existsSync()) {
    final bytes = cached.readAsBytesSync();
    if (font.sha256 == null || sha256Hex(bytes) == font.sha256) {
      return bytes;
    }
    cached.deleteSync();
  }
  final bytes = await _download(client, Uri.parse(source).resolve(font.path));
  final hash = sha256Hex(bytes);
  if (font.sha256 != null && hash != font.sha256) {
    throw FontFallbackException(
      'Checksum mismatch for ${font.path}: expected ${font.sha256}, got $hash',
    );
  }
  cached
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  return bytes;
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  exitCode = await runCli(args);
}

Future<int> runCli(List<String> args) async {
  String? webPath, sdkData;
  var lockPath = defaultLock;
  var licensePath = 'assets/fonts/OFL.txt';
  var cachePath = '.dart_tool/font_fallback_cache';
  String? source;
  var groups = <String>{'core', 'cjk'};
  var mode = 'fetch';
  var strict = false;
  for (var i = 0; i < args.length; i++) {
    String next() {
      if (i + 1 >= args.length) {
        throw FontFallbackException('value for ${args[i]} is missing');
      }
      return args[++i];
    }

    switch (args[i]) {
      case '--update-lock':
        mode = 'update';
      case '--check-sdk':
        mode = 'check';
      case '--lock':
        lockPath = next();
      case '--cache':
        cachePath = next();
      case '--license':
        licensePath = next();
      case '--source':
        source = next();
      case '--sdk-data':
        sdkData = next();
      case '--strict':
        strict = true;
      case '--groups':
        groups = next()
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet();
        if (groups.difference(<String>{'core', 'cjk'}).isNotEmpty) {
          stderr.writeln('--groups only allows core and cjk');
          return 64;
        }
      case final a when a.startsWith('--'):
        stderr.writeln('Unknown option $a');
        return 64;
      default:
        webPath = args[i];
    }
  }

  final client = HttpClient()
    ..userAgent = 'linefm-build'
    ..connectionTimeout = const Duration(seconds: 20);
  try {
    final cache = Directory(cachePath);
    switch (mode) {
      case 'update':
        final sdk = readSdk(sdkData);
        final src = source ?? defaultSource;
        final locked = <FallbackFont>[];
        await _pool(sdk.fonts, 8, (f) async {
          if (!isSafeRelativePath(f.path)) {
            throw FontFallbackException('invalid path in the SDK: ${f.path}');
          }
          final bytes = await fetchVerified(
            client,
            f,
            source: src,
            cache: cache,
            useCache: false,
          );
          locked.add(
            FallbackFont(
              f.name,
              f.path,
              sha256: sha256Hex(bytes),
              bytes: bytes.length,
            ),
          );
        });
        File(lockPath).writeAsStringSync(
          encodeLock(
            engineRevision: sdk.engineRevision,
            source: src,
            fonts: locked,
          ),
        );
        stdout.writeln(
          'fetch_font_fallback: lock file $lockPath written with ${locked.length} files',
        );
        return 0;
      case 'check':
        final lock = parseLock(File(lockPath).readAsStringSync());
        final sdk = readSdk(sdkData);
        final d = diffPaths(
          sdk.fonts.map((f) => f.path),
          lock.fonts.map((f) => f.path),
        );
        if (d.onlySdk.isEmpty && d.onlyLock.isEmpty) {
          stdout.writeln('fetch_font_fallback: lock file matches the SDK');
          return 0;
        }
        stderr.writeln(
          'fetch_font_fallback: lock file outdated (${d.onlySdk.length} new in the SDK, '
          '${d.onlyLock.length} no longer in the SDK). Run --update-lock.',
        );
        return 1;
    }

    if (webPath == null) {
      stderr.writeln(
        'Usage: dart run tool/fetch_font_fallback.dart build/web [options]',
      );
      return 64;
    }
    final web = Directory(webPath);
    if (!web.existsSync()) {
      throw FontFallbackException('${web.path} does not exist');
    }
    final ofl = File(licensePath);
    if (!ofl.existsSync()) {
      throw FontFallbackException(
        '$licensePath is missing: without the OFL license text the fonts must not '
        'be shipped (pass --license)',
      );
    }
    final lock = parseLock(File(lockPath).readAsStringSync());
    try {
      final sdk = readSdk(sdkData);
      final d = diffPaths(
        sdk.fonts.map((f) => f.path),
        lock.fonts.map((f) => f.path),
      );
      if (d.onlySdk.isNotEmpty || d.onlyLock.isNotEmpty) {
        final msg =
            'Lock file does not match the Flutter SDK (${d.onlySdk.length} paths missing), '
            'run --update-lock';
        if (strict) {
          throw FontFallbackException(msg);
        }
        stderr.writeln('fetch_font_fallback: note: $msg');
      }
    } on FontFallbackException catch (e) {
      if (strict) {
        rethrow;
      }
      stderr.writeln('fetch_font_fallback: note: ${e.message}');
    }

    final selected = lock.fonts.where((f) => groups.contains(f.group)).toList();
    final target = Directory('${web.path}/$fallbackSubdir');
    var total = 0;
    await _pool(selected, 8, (f) async {
      final bytes = await fetchVerified(
        client,
        f,
        source: source ?? lock.source,
        cache: cache,
      );
      File('${target.path}/${f.path}')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
      total += bytes.length;
    });
    File('${target.path}/OFL.txt')
        .writeAsStringSync(renderLicense(ofl.readAsStringSync()));
    stdout.writeln(
      'fetch_font_fallback: ${selected.length} files '
      '(${(total / 1048576).toStringAsFixed(1)} MiB, groups ${groups.join(',')}) '
      'under ${target.path}',
    );
    return 0;
  } on FontFallbackException catch (e) {
    stderr.writeln(e);
    return 1;
  } finally {
    client.close(force: true);
  }
}
