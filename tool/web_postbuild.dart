// Postbuild fuer die Flutter-Web-Ausgabe (Spec 6.1).
//
// Aufruf: dart run tool/web_postbuild.dart build/web [Optionen]
//
// Schritte:
//  1. main.dart.{js,wasm,mjs} -> main.<sha8>.dart.<ext>, flutter_bootstrap.js anpassen
//  2. canvaskit/ -> canvaskit/<engineRevision>/, canvasKitBaseUrl im Bootstrap setzen
//  3. Platzhalter ersetzen (Basis-URL, Search-Console-Verifikation, Build-ID im sw.js)
//  4. Hosting-Dateien aus deploy/ rendern (Header-Dateien, __CSP_CONNECT_EXTRA__)
//  5. asset-manifest.txt mit SHA-256 aller Dateien schreiben
//
// Optionen:
//  --config <datei>            Dart-Define-Datei (Standard: config/app.json, falls vorhanden)
//  --csp-connect-extra "<..>"  zusaetzliche connect-src-Quellen (sonst aus Konfiguration abgeleitet)
//  --targets <liste>           cloudflare,plesk (Standard: beide) oder none
//  --deploy-dir <ordner>       Standard: deploy
//  --hosting-out <ordner>      Standard: build/hosting
//  --base-url <url>            Standard: WEB_BASE_URL aus der Konfiguration
//  --gsc <token>               Search-Console-Verifikation (sonst GSC_VERIFICATION)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const String defaultBaseUrl = 'https://app.linefm.de';
const String cspPlaceholder = '__CSP_CONNECT_EXTRA__';
const String canvasKitMarker = '/*__CANVASKIT_BASE_URL__*/';
const String buildIdPlaceholder = '__BUILD_ID__';
const String firebaseConnectSources =
    'https://*.googleapis.com https://*.google-analytics.com https://*.analytics.google.com';

class PostbuildException implements Exception {
  PostbuildException(this.message);
  final String message;
  @override
  String toString() => 'web_postbuild: $message';
}

// ---------------------------------------------------------------------------
// SHA-256 (eigene Implementierung, damit keine zusaetzliche Abhaengigkeit noetig ist)
// ---------------------------------------------------------------------------

const List<int> _k = <int>[
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, //
  0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
  0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
  0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
  0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;

/// SHA-256 als Hex-String.
String sha256Hex(List<int> data) {
  final h = <int>[
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, //
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];
  final bitLength = data.length * 8;
  final padded = Uint8List(((data.length + 9 + 63) ~/ 64) * 64)
    ..setRange(0, data.length, data);
  padded[data.length] = 0x80;
  final view = ByteData.view(padded.buffer);
  view.setUint32(padded.length - 8, bitLength ~/ 0x100000000);
  view.setUint32(padded.length - 4, bitLength & 0xffffffff);

  final w = List<int>.filled(64, 0);
  for (var offset = 0; offset < padded.length; offset += 64) {
    for (var i = 0; i < 16; i++) {
      w[i] = view.getUint32(offset + i * 4);
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
    }
    var a = h[0], b = h[1], c = h[2], d = h[3];
    var e = h[4], f = h[5], g = h[6], hh = h[7];
    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e & 0xffffffff) & g);
      final t1 = (hh + s1 + ch + _k[i] + w[i]) & 0xffffffff;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + maj) & 0xffffffff;
      hh = g;
      g = f;
      f = e;
      e = (d + t1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & 0xffffffff;
    }
    h[0] = (h[0] + a) & 0xffffffff;
    h[1] = (h[1] + b) & 0xffffffff;
    h[2] = (h[2] + c) & 0xffffffff;
    h[3] = (h[3] + d) & 0xffffffff;
    h[4] = (h[4] + e) & 0xffffffff;
    h[5] = (h[5] + f) & 0xffffffff;
    h[6] = (h[6] + g) & 0xffffffff;
    h[7] = (h[7] + hh) & 0xffffffff;
  }
  return h.map((x) => x.toRadixString(16).padLeft(8, '0')).join();
}

// ---------------------------------------------------------------------------
// Reine Funktionen (getestet in test/tool/web_postbuild_test.dart)
// ---------------------------------------------------------------------------

/// Leitet die zusaetzlichen connect-src-Quellen aus der App-Konfiguration ab.
String deriveCspConnectExtra(Map<String, dynamic> config) {
  final sources = <String>[];
  void add(String? s) {
    if (s != null && s.isNotEmpty && !sources.contains(s)) sources.add(s);
  }

  String? origin(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  add(origin(config['UMAMI_URL']));
  final dsn = config['SENTRY_DSN'];
  if (dsn is String && dsn.trim().isNotEmpty) {
    final uri = Uri.tryParse(dsn.trim());
    if (uri != null && uri.host.isNotEmpty) {
      add('https://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}');
    }
  }
  if (config['FIREBASE_ENABLED'] == true) {
    firebaseConnectSources.split(' ').forEach(add);
  }
  return sources.join(' ');
}

/// Ersetzt `__CSP_CONNECT_EXTRA__` (inklusive des vorangehenden Leerzeichens).
String renderCspPlaceholder(String text, String extra) {
  final replacement = extra.trim().isEmpty ? '' : ' ${extra.trim()}';
  return text.replaceAll(' $cspPlaceholder', replacement).replaceAll(cspPlaceholder, extra.trim());
}

/// Setzt das Search-Console-Token ein oder entfernt das Meta-Tag, wenn leer.
String renderGscVerification(String html, String token) {
  const tag = '<meta name="google-site-verification" content="__GSC_VERIFICATION__">';
  if (token.trim().isEmpty) {
    return html.replaceAll(RegExp('[ \\t]*${RegExp.escape(tag)}\\r?\\n?'), '');
  }
  return html.replaceAll(
    tag,
    '<meta name="google-site-verification" content="${const HtmlEscape(HtmlEscapeMode.attribute).convert(token.trim())}">',
  );
}

/// Liest `_flutter.buildConfig`, benennt Pfade um und liefert das neue Bootstrap.
String rewriteBootstrap(
  String bootstrap, {
  required Map<String, String> renamedMain,
  required String engineRevision,
}) {
  final pattern = RegExp(r'^_flutter\.buildConfig = (\{.*\});$', multiLine: true);
  final match = pattern.firstMatch(bootstrap);
  if (match == null) {
    throw PostbuildException('_flutter.buildConfig in flutter_bootstrap.js nicht gefunden');
  }
  final cfg = jsonDecode(match.group(1)!) as Map<String, dynamic>;
  final builds = (cfg['builds'] as List<dynamic>).cast<Map<String, dynamic>>();
  for (final b in builds) {
    for (final key in <String>['mainJsPath', 'mainWasmPath', 'jsSupportRuntimePath']) {
      final old = b[key];
      if (old is String && renamedMain.containsKey(old)) b[key] = renamedMain[old];
    }
  }
  final hashes = cfg['wasmHashes'];
  if (hashes is Map<String, dynamic>) {
    for (final e in renamedMain.entries) {
      if (hashes.containsKey(e.key)) hashes[e.value] = hashes.remove(e.key);
    }
  }
  var out = bootstrap.replaceRange(match.start, match.end, '_flutter.buildConfig = ${jsonEncode(cfg)};');
  if (!out.contains(canvasKitMarker)) {
    throw PostbuildException(
      'Marke $canvasKitMarker fehlt: web/flutter_bootstrap.js muss das eigene Template sein',
    );
  }
  out = out.replaceFirst(canvasKitMarker, "config.canvasKitBaseUrl = 'canvaskit/$engineRevision/';");
  return out;
}

/// Ersetzt die Standard-Domain durch eine andere Basis-URL (nur Textdateien).
String rewriteBaseUrl(String text, String baseUrl) {
  final clean = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  return clean == defaultBaseUrl ? text : text.replaceAll(defaultBaseUrl, clean);
}

// ---------------------------------------------------------------------------
// Ablauf
// ---------------------------------------------------------------------------

class PostbuildOptions {
  PostbuildOptions({
    required this.webDir,
    this.config = const <String, dynamic>{},
    this.cspConnectExtra,
    this.targets = const <String>{'cloudflare', 'plesk'},
    this.deployDir = 'deploy',
    this.hostingOut = 'build/hosting',
    this.baseUrl,
    this.gsc,
  });

  final Directory webDir;
  final Map<String, dynamic> config;
  final String? cspConnectExtra;
  final Set<String> targets;
  final String deployDir;
  final String hostingOut;
  final String? baseUrl;
  final String? gsc;
}

String _rel(Directory root, FileSystemEntity e) {
  final rootPath = root.absolute.path.replaceAll('\\', '/');
  final p = e.absolute.path.replaceAll('\\', '/');
  return p.substring(rootPath.length).replaceFirst(RegExp('^/'), '');
}

List<File> _filesIn(Directory dir) => dir.listSync(recursive: true).whereType<File>().toList()
  ..sort((a, b) => a.path.compareTo(b.path));

const Set<String> _textExt = <String>{'html', 'txt', 'xml', 'js', 'json', 'webmanifest', 'conf', 'yml', 'yaml'};

bool _isText(String path) {
  final name = path.split('/').last;
  if (name == '_headers' || name == '_redirects' || name == '.htaccess') return true;
  final dot = name.lastIndexOf('.');
  return dot >= 0 && _textExt.contains(name.substring(dot + 1));
}

/// Fuehrt alle Schritte aus; liefert die geschriebenen Hosting-Dateien (relativ).
List<String> runPostbuild(PostbuildOptions o) {
  final web = o.webDir;
  if (!web.existsSync()) throw PostbuildException('${web.path} existiert nicht (zuerst flutter build web)');
  final bootstrapFile = File('${web.path}/flutter_bootstrap.js');
  if (!bootstrapFile.existsSync()) throw PostbuildException('flutter_bootstrap.js fehlt');

  // 1. main.dart.* umbenennen
  final renamed = <String, String>{};
  for (final ext in <String>['js', 'wasm', 'mjs']) {
    final f = File('${web.path}/main.dart.$ext');
    if (!f.existsSync()) continue;
    final hash = sha256Hex(f.readAsBytesSync()).substring(0, 8);
    final name = 'main.$hash.dart.$ext';
    f.renameSync('${web.path}/$name');
    renamed['main.dart.$ext'] = name;
  }
  if (renamed.isEmpty) {
    throw PostbuildException('keine main.dart.* gefunden (Postbuild schon gelaufen?)');
  }

  final bootstrap = bootstrapFile.readAsStringSync();
  final revMatch = RegExp(r'"engineRevision":"([0-9a-f]{40})"').firstMatch(bootstrap);
  if (revMatch == null) throw PostbuildException('engineRevision nicht gefunden');
  final revision = revMatch.group(1)!;
  bootstrapFile.writeAsStringSync(
    rewriteBootstrap(bootstrap, renamedMain: renamed, engineRevision: revision),
  );

  // 2. canvaskit/ -> canvaskit/<revision>/
  final canvasKit = Directory('${web.path}/canvaskit');
  if (canvasKit.existsSync()) {
    final tmp = Directory('${web.path}/.canvaskit_tmp');
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    canvasKit.renameSync(tmp.path);
    Directory('${web.path}/canvaskit').createSync();
    tmp.renameSync('${web.path}/canvaskit/$revision');
  }

  // 3. Platzhalter
  final baseUrl = o.baseUrl ?? (o.config['WEB_BASE_URL'] as String?) ?? defaultBaseUrl;
  final gsc = o.gsc ?? (o.config['GSC_VERIFICATION'] as String?) ?? '';
  for (final name in <String>[
    'index.html', 'sitemap.xml', 'robots.txt', 'llms.txt', 'manifest.webmanifest',
  ]) {
    final f = File('${web.path}/$name');
    if (!f.existsSync()) continue;
    var text = rewriteBaseUrl(f.readAsStringSync(), baseUrl);
    if (name == 'index.html') text = renderGscVerification(text, gsc);
    f.writeAsStringSync(text);
  }

  // 4. Hosting-Dateien
  final extra = o.cspConnectExtra ?? deriveCspConnectExtra(o.config);
  final written = <String>[];
  String renderHosting(String text) => renderCspPlaceholder(text, extra);
  final deploy = Directory(o.deployDir);
  if (deploy.existsSync()) {
    if (o.targets.contains('cloudflare')) {
      for (final n in <String>['_headers', '_redirects']) {
        final src = File('${deploy.path}/cloudflare/$n');
        if (src.existsSync()) {
          File('${web.path}/$n').writeAsStringSync(renderHosting(src.readAsStringSync()));
          written.add(n);
        }
      }
    }
    if (o.targets.contains('plesk')) {
      final src = File('${deploy.path}/plesk/.htaccess');
      if (src.existsSync()) {
        File('${web.path}/.htaccess').writeAsStringSync(renderHosting(src.readAsStringSync()));
        written.add('.htaccess');
      }
    }
    final out = Directory(o.hostingOut);
    if (out.existsSync()) out.deleteSync(recursive: true);
    for (final target in <String>['nginx', 'traefik', 'plesk', 'cloudflare']) {
      final dir = Directory('${deploy.path}/$target');
      if (!dir.existsSync()) continue;
      for (final f in _filesIn(dir)) {
        final rel = _rel(deploy, f);
        final dst = File('${out.path}/$rel')..createSync(recursive: true);
        if (_isText(rel)) {
          dst.writeAsStringSync(renderHosting(f.readAsStringSync()));
        } else {
          dst.writeAsBytesSync(f.readAsBytesSync());
        }
        written.add('${o.hostingOut}/$rel');
      }
    }
  }

  // 5. Build-ID (sw.js) und asset-manifest.txt
  final entries = <String, (String, int)>{};
  for (final f in _filesIn(web)) {
    final rel = _rel(web, f);
    if (rel == 'asset-manifest.txt' || rel == 'sw.js') continue;
    final bytes = f.readAsBytesSync();
    entries[rel] = (sha256Hex(bytes), bytes.length);
  }
  final buildId = sha256Hex(
    utf8.encode(entries.entries.map((e) => '${e.key}:${e.value.$1}').join('\n')),
  ).substring(0, 12);
  final sw = File('${web.path}/sw.js');
  if (sw.existsSync()) {
    final text = sw.readAsStringSync().replaceAll(buildIdPlaceholder, buildId);
    sw.writeAsStringSync(text);
    entries['sw.js'] = (sha256Hex(utf8.encode(text)), utf8.encode(text).length);
  }
  final sorted = entries.keys.toList()..sort();
  final manifest = StringBuffer();
  for (final k in sorted) {
    manifest.writeln('${entries[k]!.$1}  ${entries[k]!.$2}  $k');
  }
  File('${web.path}/asset-manifest.txt').writeAsStringSync(manifest.toString());
  return written;
}

Map<String, dynamic> _readConfig(String? path) {
  final candidates = <String>[?path, if (path == null) 'config/app.json'];
  for (final c in candidates) {
    final f = File(c);
    if (f.existsSync()) return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    if (path != null) throw PostbuildException('Konfiguration $path nicht gefunden');
  }
  return <String, dynamic>{};
}

void main(List<String> args) => exitCode = runCli(args);

/// Kommandozeilen-Einstieg; liefert den Exit-Code.
int runCli(List<String> args) {
  String? webPath, configPath, extra, deployDir, hostingOut, baseUrl, gsc, targets;
  for (var i = 0; i < args.length; i++) {
    String next() {
      if (i + 1 >= args.length) throw PostbuildException('Wert fuer ${args[i]} fehlt');
      return args[++i];
    }

    switch (args[i]) {
      case '--config':
        configPath = next();
      case '--csp-connect-extra':
        extra = next();
      case '--targets':
        targets = next();
      case '--deploy-dir':
        deployDir = next();
      case '--hosting-out':
        hostingOut = next();
      case '--base-url':
        baseUrl = next();
      case '--gsc':
        gsc = next();
      case final a when a.startsWith('--'):
        stderr.writeln('Unbekannte Option $a');
        return 64;
      default:
        webPath = args[i];
    }
  }
  if (webPath == null) {
    stderr.writeln('Aufruf: dart run tool/web_postbuild.dart build/web [Optionen]');
    return 64;
  }
  try {
    final written = runPostbuild(PostbuildOptions(
      webDir: Directory(webPath),
      config: _readConfig(configPath),
      cspConnectExtra: extra ?? Platform.environment['CSP_CONNECT_EXTRA'],
      targets: targets == null
          ? const <String>{'cloudflare', 'plesk'}
          : targets.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty && s != 'none').toSet(),
      deployDir: deployDir ?? 'deploy',
      hostingOut: hostingOut ?? 'build/hosting',
      baseUrl: baseUrl,
      gsc: gsc,
    ));
    stdout.writeln('web_postbuild: fertig (${written.length} Hosting-Dateien geschrieben)');
    return 0;
  } on PostbuildException catch (e) {
    stderr.writeln(e);
    return 1;
  }
}
