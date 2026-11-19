// Ersatzschriften fuer Flutter Web selbst hosten (L14).
//
// Die Web-Engine laedt fehlende Zeichen (Emoji, Kyrillisch, CJK, Symbole) als
// Noto-Schriften nach, und zwar von `fontFallbackBaseUrl + <pfad>`. Ohne eigene
// Dateien unter assets/fonts/fallback/ erscheinen solche Zeichen als Kaestchen.
// Dieses Werkzeug legt genau die Dateien ab, die die Engine anfragt.
//
// Aufrufe:
//   dart run tool/fetch_font_fallback.dart build/web [Optionen]
//       Laedt die Dateien aus der Sperrdatei (Pfad, SHA-256, Groesse), prueft
//       jede Pruefsumme und legt sie unter build/web/assets/fonts/fallback/ ab.
//   dart run tool/fetch_font_fallback.dart --update-lock [--sdk-data <datei>]
//       Liest die Liste aus dem Flutter-SDK (font_fallback_data.dart), laedt
//       alles frisch aus dem Netz (ohne Cache, S3-05) und schreibt die
//       Sperrdatei neu (nach jedem Flutter-Update).
//   dart run tool/fetch_font_fallback.dart --check-sdk [--sdk-data <datei>]
//       Vergleicht Sperrdatei und SDK-Liste; Exit 1 bei Abweichung.
//
// Optionen:
//   --lock <datei>        Standard: tool/font_fallback.lock.json
//   --groups <liste>      core,cjk (Standard: beide) oder core
//   --cache <ordner>      Standard: .dart_tool/font_fallback_cache
//   --source <url>        Standard: https://fonts.gstatic.com/s/
//   --sdk-data <datei>    Standard: aus dem laufenden Flutter-SDK abgeleitet
//   --license <datei>     OFL-Text (Standard: assets/fonts/OFL.txt), landet als OFL.txt daneben.
//                         Fehlt die Datei, bricht der Aufruf mit Exit 1 ab (R3-P07).
//   --strict              Abweichung zwischen Sperrdatei und SDK ist ein Fehler
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'web_postbuild.dart' show sha256Hex;

const String defaultSource = 'https://fonts.gstatic.com/s/';
const String defaultLock = 'tool/font_fallback.lock.json';
const String fallbackSubdir = 'assets/fonts/fallback';

/// Roboto ist die Standardschrift der Engine und kommt ueber dieselbe Basis-URL
/// (skwasm/skwasm_impl/font_collection.dart und canvaskit/fonts.dart).
final RegExp _robotoPattern = RegExp(r"fontFallbackBaseUrl\}(roboto/[^']+)'");

/// Familien, deren Dateien gross sind und nur fuer CJK-Text gebraucht werden.
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

/// Gruppe eines Pfads: `cjk` fuer die grossen CJK-Familien, sonst `core`.
String groupOf(String path) =>
    cjkPrefixes.any(path.startsWith) ? 'cjk' : 'core';

/// Liest alle `NotoFont('<name>', '<pfad>', ...)` aus font_fallback_data.dart.
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

/// Liest den Roboto-Pfad aus fonts.dart bzw. font_collection.dart.
String? parseRobotoPath(String source) =>
    _robotoPattern.firstMatch(source)?.group(1);

/// Lizenzdatei fuer den Fallback-Ordner: eigener Urheberkopf, danach der
/// OFL-Text ab "This Font Software is licensed ..." aus der Vorlage.
String renderLicense(String oflTemplate) {
  final start = oflTemplate.indexOf('This Font Software is licensed');
  final body = start >= 0 ? oflTemplate.substring(start) : oflTemplate;
  return 'Noto fonts: Copyright The Noto Project Authors (https://github.com/notofonts)\n'
      'Noto Color Emoji: Copyright Google LLC (https://github.com/googlefonts/noto-emoji)\n'
      'Roboto: Copyright 2011 The Roboto Project Authors (https://github.com/googlefonts/roboto-classic)\n'
      'Quelle: Google Fonts, Liste und Pruefsummen in tool/font_fallback.lock.json\n\n'
      '$body';
}

/// Prueft, dass ein Pfad relativ bleibt und keine Ordner verlaesst.
bool isSafeRelativePath(String path) {
  if (path.isEmpty || path.startsWith('/') || path.contains('\\')) {
    return false;
  }
  if (path.contains(':')) {
    return false;
  }
  return path.split('/').every((s) => s.isNotEmpty && s != '.' && s != '..');
}

/// Liest die Sperrdatei.
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
      throw FontFallbackException(
        'unzulaessiger Pfad in der Sperrdatei: ${f.path}',
      );
    }
    if (f.sha256 == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(f.sha256!)) {
      throw FontFallbackException('Pruefsumme fehlt fuer ${f.path}');
    }
  }
  return (
    engineRevision: json['engineRevision'] as String? ?? '',
    source: json['source'] as String? ?? defaultSource,
    fonts: fonts,
  );
}

/// Schreibt die Sperrdatei (stabil sortiert, damit Diffs lesbar bleiben).
String encodeLock({
  required String engineRevision,
  required String source,
  required List<FallbackFont> fonts,
}) {
  final sorted = fonts.toList()..sort((a, b) => a.path.compareTo(b.path));
  int sum(String g) =>
      sorted.where((f) => f.group == g).fold(0, (s, f) => s + (f.bytes ?? 0));
  return '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'comment': 'Erzeugt mit dart run tool/fetch_font_fallback.dart --update-lock. '
        'Noto-Schriften und Roboto: SIL Open Font License 1.1 (docs/LIZENZEN-DRITTE.md).',
    'engineRevision': engineRevision,
    'source': source,
    'totals': <String, int>{'core': sum('core'), 'cjk': sum('cjk'), 'files': sorted.length},
    'fonts': [for (final f in sorted) f.toJson()],
  })}\n';
}

/// Unterschiede zwischen zwei Pfadlisten (nur im SDK, nur in der Sperrdatei).
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
// SDK und Netz
// ---------------------------------------------------------------------------

/// Flutter-Wurzel: FLUTTER_ROOT oder aus dem laufenden Dart abgeleitet
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
      '${data.path} nicht gefunden (flutter precache --web oder --sdk-data angeben)',
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
  throw FontFallbackException('Download fehlgeschlagen: $url ($last)');
}

/// Fuehrt [task] fuer alle Eintraege mit begrenzter Parallelitaet aus.
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

/// Holt eine Datei (Cache oder Netz) und prueft die Pruefsumme.
///
/// Mit [useCache] = false wird immer aus dem Netz geladen (fuer --update-lock:
/// ohne bekannte Pruefsumme darf ein alter oder fremder Cache-Inhalt nicht in
/// die Sperrdatei wandern). Das Ergebnis landet trotzdem im Cache.
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
      'Pruefsumme passt nicht fuer ${font.path}: erwartet ${font.sha256}, erhalten $hash',
    );
  }
  cached
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  return bytes;
}

// ---------------------------------------------------------------------------
// Einstieg
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
        throw FontFallbackException('Wert fuer ${args[i]} fehlt');
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
          stderr.writeln('--groups erlaubt nur core und cjk');
          return 64;
        }
      case final a when a.startsWith('--'):
        stderr.writeln('Unbekannte Option $a');
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
            throw FontFallbackException('unzulaessiger Pfad im SDK: ${f.path}');
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
          'fetch_font_fallback: Sperrdatei $lockPath mit ${locked.length} Dateien geschrieben',
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
          stdout.writeln('fetch_font_fallback: Sperrdatei passt zum SDK');
          return 0;
        }
        stderr.writeln(
          'fetch_font_fallback: Sperrdatei veraltet (${d.onlySdk.length} neu im SDK, '
          '${d.onlyLock.length} nicht mehr im SDK). --update-lock ausfuehren.',
        );
        return 1;
    }

    if (webPath == null) {
      stderr.writeln(
        'Aufruf: dart run tool/fetch_font_fallback.dart build/web [Optionen]',
      );
      return 64;
    }
    final web = Directory(webPath);
    if (!web.existsSync()) {
      throw FontFallbackException('${web.path} existiert nicht');
    }
    final ofl = File(licensePath);
    if (!ofl.existsSync()) {
      throw FontFallbackException(
        '$licensePath fehlt: ohne OFL-Lizenztext duerfen die Schriften nicht '
        'ausgeliefert werden (--license angeben)',
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
            'Sperrdatei passt nicht zum Flutter-SDK (${d.onlySdk.length} Pfade fehlen), '
            '--update-lock ausfuehren';
        if (strict) {
          throw FontFallbackException(msg);
        }
        stderr.writeln('fetch_font_fallback: WARNUNG: $msg');
      }
    } on FontFallbackException catch (e) {
      if (strict) {
        rethrow;
      }
      stderr.writeln('fetch_font_fallback: WARNUNG: ${e.message}');
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
      'fetch_font_fallback: ${selected.length} Dateien '
      '(${(total / 1048576).toStringAsFixed(1)} MiB, Gruppen ${groups.join(',')}) '
      'unter ${target.path}',
    );
    return 0;
  } on FontFallbackException catch (e) {
    stderr.writeln(e);
    return 1;
  } finally {
    client.close(force: true);
  }
}
