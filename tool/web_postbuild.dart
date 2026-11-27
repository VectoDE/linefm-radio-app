// Postbuild for the Flutter web output (spec 6.1).
//
// Usage: dart run tool/web_postbuild.dart build/web [options]
//
// Schritte:
//  1. main.dart.{js,wasm,mjs} -> main.<sha8>.dart.<ext>, flutter_bootstrap.js anpassen
//  2. canvaskit/ -> canvaskit/<engineRevision>/, set canvasKitBaseUrl in the bootstrap
//  3. Replace placeholders (base URL, Search Console verification, build ID in sw.js,
//     lastmod of the sitemap = build date, SOURCE_DATE_EPOCH if set)
//  4. Render hosting files from deploy/ (header files, __CSP_CONNECT_EXTRA__,
//     __CSP_SCRIPT_EXTRA__, __CSP_IMG_EXTRA__; www.gstatic.com for Google Cast always,
//     Google tag sources only with GTM_ID or GA4_MEASUREMENT_ID in the configuration)
//  5. Remove ballast (source maps, *.symbols, unused engine variants, default Flutter SW)
//  6. Write asset-manifest.txt with the SHA-256 of all files
//  7. Precompress: <file>.gz (gzip 9) and <file>.br (Brotli 11 via node,
//     otherwise a warning) next to every compressible file for gzip_static/brotli_static
//
// Beforehand: security.txt without placeholders, fallback fonts including OFL.txt,
// app links under .well-known/ (assetlinks.json, apple-app-site-association) with
// values from the environment or configuration: ANDROID_CERT_SHA256 (SHA-256 of the
// Play signing certificate, several comma-separated) and APPLE_TEAM_ID. Without a value
// the file is removed from the output (warning, abort with --strict), so that
// no placeholder goes live.
//
// Optionen:
//  --config <file>             Dart define file (default: config/app.json, if present)
//  --csp-connect-extra "<..>"  additional connect-src sources (otherwise derived from the configuration)
//  --targets <list>            cloudflare,plesk (default: both) or none
//  --deploy-dir <folder>       default: deploy
//  --hosting-out <folder>      default: build/hosting
//  --base-url <url>            default: WEB_BASE_URL from the configuration
//  --gsc <token>               Search Console verification (otherwise GSC_VERIFICATION)
//  --strict                    abort while placeholders ({{...}}) remain in .well-known/
//  --keep-debug                do not remove source maps, *.symbols and engine variants
//  --no-precompress            write no .gz/.br files (e.g. Cloudflare Pages only)
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const String defaultBaseUrl = 'https://app.linefm.de';
const String cspPlaceholder = '__CSP_CONNECT_EXTRA__';
const String cspScriptPlaceholder = '__CSP_SCRIPT_EXTRA__';
const String cspImgPlaceholder = '__CSP_IMG_EXTRA__';

/// Sources for Google Tag Manager / GA4 per the Google guide "Use a Content
/// Security Policy with Google Tag Manager / Google Analytics 4"
/// (developers.google.com/tag-platform/security/guides/csp). Only if
/// GTM_ID or GA4_MEASUREMENT_ID is set; otherwise the CSP stays strict.
/// Deviation: inline scripts are not needed (the loader lives in
/// web/analytics.js), and instead of `https://*.google.com` only
/// `https://*.analytics.google.com` is listed (advertising features are off). GTM tags of
/// type "Custom HTML" and custom JS variables
/// deliberately do not work under this CSP.
const String googleTagScriptSources = 'https://www.googletagmanager.com';
const String googleTagImgSources =
    'https://www.googletagmanager.com https://*.google-analytics.com';
const String googleTagConnectSources =
    'https://www.googletagmanager.com https://*.google-analytics.com https://*.analytics.google.com';

final RegExp _gtmId = RegExp(r'^GTM-[A-Z0-9]{4,12}$');
final RegExp _ga4Id = RegExp(r'^G-[A-Z0-9]{4,16}$');

/// Is Google measurement configured (valid GTM_ID or GA4_MEASUREMENT_ID)?
/// Invalid values abort, so that no typo silently turns everything off.
bool googleTagConfigured(Map<String, dynamic> config) {
  var any = false;
  for (final (key, re) in <(String, RegExp)>[
    ('GTM_ID', _gtmId),
    ('GA4_MEASUREMENT_ID', _ga4Id),
  ]) {
    final v = config[key];
    if (v is! String || v.trim().isEmpty) {
      continue;
    }
    if (!re.hasMatch(v.trim())) {
      throw PostbuildException('$key has an invalid format: $v');
    }
    any = true;
  }
  return any;
}

const String canvasKitMarker = '/*__CANVASKIT_BASE_URL__*/';
const String buildIdPlaceholder = '__BUILD_ID__';

/// Placeholder for the year range of the copyright line in index.html.
const String copyrightYearsPlaceholder = '__COPYRIGHT_YEARS__';

/// First year of the copyright line. Counterpart: cmake/copyright.cmake.
const int copyrightFirstYear = 2026;
const String firebaseConnectSources =
    'https://*.googleapis.com https://*.google-analytics.com https://*.analytics.google.com';

class PostbuildException implements Exception {
  PostbuildException(this.message);
  final String message;
  @override
  String toString() => 'web_postbuild: $message';
}

// ---------------------------------------------------------------------------
// SHA-256 (own implementation, so that no additional dependency is needed)
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

/// SHA-256 as a hex string.
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

/// Derives the additional connect-src sources from the app configuration.
String deriveCspConnectExtra(Map<String, dynamic> config) {
  final sources = <String>[];
  void add(String? s) {
    if (s != null && s.isNotEmpty && !sources.contains(s)) {
      sources.add(s);
    }
  }

  String? origin(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }
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
  if (googleTagConfigured(config)) {
    googleTagConnectSources.split(' ').forEach(add);
  }
  return sources.join(' ');
}

/// Google Cast in the web version: web/cast.js injects the Cast sender script
/// from www.gstatic.com, which loads the Cast framework from the same host
/// (developers.google.com/cast/docs/web_sender/integrate). Only after consent;
/// the CSP merely permits it.
const String googleCastScriptSources = 'https://www.gstatic.com';

/// Additional script-src sources: Google Cast always, Google tag only with IDs.
String deriveCspScriptExtra(Map<String, dynamic> config) => <String>[
  googleCastScriptSources,
  if (googleTagConfigured(config)) googleTagScriptSources,
].join(' ');

/// Additional img-src sources (only with Google IDs).
String deriveCspImgExtra(Map<String, dynamic> config) =>
    googleTagConfigured(config) ? googleTagImgSources : '';

/// Replaces [placeholder] (default `__CSP_CONNECT_EXTRA__`, including the
/// preceding space) with [extra].
String renderCspPlaceholder(
  String text,
  String extra, {
  String placeholder = cspPlaceholder,
}) {
  final replacement = extra.trim().isEmpty ? '' : ' ${extra.trim()}';
  return text
      .replaceAll(' $placeholder', replacement)
      .replaceAll(placeholder, extra.trim());
}

/// SHA-256 of [text] (UTF-8) as a CSP hash source (`'sha256-<base64>'`).
String cspSha256(String text) {
  final hex = sha256Hex(utf8.encode(text));
  final bytes = <int>[
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
  return "'sha256-${base64.encode(bytes)}'";
}

/// Hash sources for every inline `<style>` block in [html] (static shell,
/// noscript). The style elements of the Flutter engine get the build nonce
/// instead, see [renderStyleNonce]. Sorted, no duplicates.
List<String> inlineStyleHashes(String html) {
  final hashes = <String>{};
  for (final m in RegExp(
    r'<style(?:\s[^>]*)?>([\s\S]*?)</style>',
    caseSensitive: false,
  ).allMatches(html)) {
    hashes.add(cspSha256(m.group(1)!));
  }
  return hashes.toList()..sort();
}

/// Placeholder for the style nonce in web/flutter_bootstrap.js.
const String cspStyleNoncePlaceholder = '__CSP_STYLE_NONCE__';

/// Random nonce (128 bit, base64) for the engine's style elements. It is
/// fixed per build, not per response (static hosting), so it only keeps
/// inline styles from foreign markup out as long as the nonce is unknown;
/// scripts never depend on it.
String newStyleNonce([Random? random]) {
  final r = random ?? Random.secure();
  return base64.encode(List<int>.generate(16, (_) => r.nextInt(256)));
}

/// Writes [nonce] into [bootstrap]; returns null if the placeholder is
/// missing.
String? renderStyleNonce(String bootstrap, String nonce) =>
    bootstrap.contains(cspStyleNoncePlaceholder)
    ? bootstrap.replaceAll(cspStyleNoncePlaceholder, nonce)
    : null;

/// The `style-src` directive (not `style-src-elem` / `style-src-attr`) with
/// its `'unsafe-inline'` source.
final RegExp _styleSrcUnsafeInline = RegExp(
  r"(\bstyle-src\s[^;\x22\n]*?) 'unsafe-inline'",
);

/// Replaces `'unsafe-inline'` in the style-src directive of [text] with
/// [hashes]. Other directives stay untouched. Throws if the directive would
/// lose `'unsafe-inline'` without a nonce: the Flutter engine's style
/// elements would then be blocked.
String renderStyleHashes(String text, List<String> hashes) {
  if (!_styleSrcUnsafeInline.hasMatch(text)) return text;
  if (!hashes.any((h) => h.startsWith("'nonce-"))) {
    throw PostbuildException(
      "style-src would lose 'unsafe-inline' without a nonce "
      '(web/flutter_bootstrap.js needs $cspStyleNoncePlaceholder)',
    );
  }
  return text.replaceAllMapped(
    _styleSrcUnsafeInline,
    (m) => '${m.group(1)} ${hashes.join(' ')}',
  );
}

/// Nonce already written into a built flutter_bootstrap.js (second run on
/// the same output), or null.
String? existingStyleNonce(String bootstrap) =>
    RegExp(r"\bnonce: '([A-Za-z0-9+/]{22}==)'").firstMatch(bootstrap)?.group(1);

/// Inserts the Search Console token or removes the meta tag if empty.
String renderGscVerification(String html, String token) {
  const tag =
      '<meta name="google-site-verification" content="__GSC_VERIFICATION__">';
  if (token.trim().isEmpty) {
    return html.replaceAll(RegExp('[ \\t]*${RegExp.escape(tag)}\\r?\\n?'), '');
  }
  return html.replaceAll(
    tag,
    '<meta name="google-site-verification" content="${const HtmlEscape(HtmlEscapeMode.attribute).convert(token.trim())}">',
  );
}

/// Reads `_flutter.buildConfig`, renames paths and returns the new bootstrap.
String rewriteBootstrap(
  String bootstrap, {
  required Map<String, String> renamedMain,
  required String engineRevision,
}) {
  final pattern = RegExp(
    r'^_flutter\.buildConfig = (\{.*\});$',
    multiLine: true,
  );
  final match = pattern.firstMatch(bootstrap);
  if (match == null) {
    throw PostbuildException(
      '_flutter.buildConfig not found in flutter_bootstrap.js',
    );
  }
  final cfg = jsonDecode(match.group(1)!) as Map<String, dynamic>;
  final builds = (cfg['builds'] as List<dynamic>).cast<Map<String, dynamic>>();
  for (final b in builds) {
    for (final key in <String>[
      'mainJsPath',
      'mainWasmPath',
      'jsSupportRuntimePath',
    ]) {
      final old = b[key];
      if (old is String && renamedMain.containsKey(old)) {
        b[key] = renamedMain[old];
      }
    }
  }
  final hashes = cfg['wasmHashes'];
  if (hashes is Map<String, dynamic>) {
    for (final e in renamedMain.entries) {
      if (hashes.containsKey(e.key)) {
        hashes[e.value] = hashes.remove(e.key);
      }
    }
  }
  var out = bootstrap.replaceRange(
    match.start,
    match.end,
    '_flutter.buildConfig = ${jsonEncode(cfg)};',
  );
  if (!out.contains(canvasKitMarker)) {
    throw PostbuildException(
      'Marker $canvasKitMarker is missing: web/flutter_bootstrap.js must be the custom template',
    );
  }
  out = out.replaceFirst(
    canvasKitMarker,
    "config.canvasKitBaseUrl = 'canvaskit/$engineRevision/';",
  );
  return out;
}

/// Engine variants that the custom bootstrap never loads (flutter_bootstrap.js, Flutter 3.50):
///  - `wimp.*` only with `enableWimp`, `webparagraph/` only with `preferWebParagraph`
///    (web/flutter_bootstrap.js sets neither).
///  - `*.symbols` are debug symbols for stack traces, never part of the load path.
/// Kept are canvaskit.{js,wasm} (dart2js fallback in Firefox/Safari),
/// chromium/ (dart2js fallback in Chromium), skwasm.* and skwasm_heavy.* (dart2wasm).
bool isPrunableEngineFile(String relPath) {
  final p = relPath.replaceAll('\\', '/');
  final name = p.split('/').last;
  if (name.endsWith('.symbols') || name.endsWith('.map')) {
    return true;
  }
  if (p.contains('webparagraph/')) {
    return true;
  }
  return RegExp(r'^wimp\.(js|wasm)$').hasMatch(name) &&
      p.contains('canvaskit/');
}

/// Removes entries for removed engine variants from `wasmHashes`.
String pruneWasmHashes(String bootstrap) {
  final pattern = RegExp(
    r'^_flutter.buildConfig = (\{.*\});$',
    multiLine: true,
  );
  final match = pattern.firstMatch(bootstrap);
  if (match == null) {
    return bootstrap;
  }
  final cfg = jsonDecode(match.group(1)!) as Map<String, dynamic>;
  final hashes = cfg['wasmHashes'];
  if (hashes is Map<String, dynamic>) {
    hashes.removeWhere(
      (k, _) => k == 'wimp.wasm' || k.startsWith('webparagraph/'),
    );
  }
  return bootstrap.replaceRange(
    match.start,
    match.end,
    '_flutter.buildConfig = ${jsonEncode(cfg)};',
  );
}

/// Sets every `<lastmod>` of the sitemap to [date] (UTC, `YYYY-MM-DD`).
/// Idempotent: a second run only rewrites the date.
String renderSitemapLastmod(String xml, DateTime date) {
  final utc = date.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  final day = '${utc.year}-${two(utc.month)}-${two(utc.day)}';
  return xml.replaceAll(
    RegExp('<lastmod>[^<]*</lastmod>'),
    '<lastmod>$day</lastmod>',
  );
}

/// Build date: SOURCE_DATE_EPOCH (reproducible builds), otherwise now.
DateTime buildDate([Map<String, String>? env]) {
  final epoch = int.tryParse(
    (env ?? Platform.environment)['SOURCE_DATE_EPOCH'] ?? '',
  );
  return epoch == null
      ? DateTime.now().toUtc()
      : DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
}

/// Year range of the copyright line: first year to the year of the build, with
/// the same year only one (e.g. `2026` or `2026-2027`).
String copyrightYears(DateTime build) => build.year > copyrightFirstYear
    ? '$copyrightFirstYear-${build.year}'
    : '$copyrightFirstYear';

/// Replaces the default domain with another base URL (text files only).
String rewriteBaseUrl(String text, String baseUrl) {
  final clean = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  return clean == defaultBaseUrl
      ? text
      : text.replaceAll(defaultBaseUrl, clean);
}

// ---------------------------------------------------------------------------
// App-Links (.well-known)
// ---------------------------------------------------------------------------

/// Templates under .well-known/ with their placeholder.
const Map<String, String> appLinkTemplates = <String, String>{
  'assetlinks.json': 'ANDROID_CERT_SHA256',
  'apple-app-site-association': 'APPLE_TEAM_ID',
};

final RegExp _certFingerprint = RegExp(r'^([0-9A-F]{2}:){31}[0-9A-F]{2}$');
final RegExp _teamId = RegExp(r'^[A-Z0-9]{10}$');

/// Value for [key]: environment before configuration, empty = not set.
String? appLinkValue(
  String key,
  Map<String, dynamic> config, [
  Map<String, String>? env,
]) {
  final raw =
      (env ?? Platform.environment)[key] ?? (config[key] as String?) ?? '';
  final v = raw.trim();
  return v.isEmpty ? null : v;
}

/// Inserts [value] into the template [file]. Fingerprints: comma-separated, each
/// 32 bytes as hex with colons (uppercase); team ID: 10 characters.
String renderAppLinkTemplate(String file, String text, String value) {
  final key = appLinkTemplates[file]!;
  if (key == 'ANDROID_CERT_SHA256') {
    // Several fingerprints (app signature from Play and upload key for
    // the GitHub APK), order is kept, duplicates are dropped.
    final prints = value
        .split(',')
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (prints.isEmpty || !prints.every(_certFingerprint.hasMatch)) {
      throw PostbuildException(
        'ANDROID_CERT_SHA256 does not have the format AA:BB:...(32 bytes)',
      );
    }
    return text.replaceAll('"{{$key}}"', prints.map(jsonEncode).join(', '));
  }
  if (!_teamId.hasMatch(value)) {
    throw PostbuildException(
      'APPLE_TEAM_ID must have 10 characters (A-Z, 0-9)',
    );
  }
  return text.replaceAll('{{$key}}', value);
}

/// Fills or removes the app link files; returns the names of the filled ones.
List<String> renderAppLinks(
  Directory web,
  Map<String, dynamic> config, {
  required bool strict,
  Map<String, String>? env,
}) {
  final done = <String>[];
  for (final entry in appLinkTemplates.entries) {
    final f = File('${web.path}/.well-known/${entry.key}');
    if (!f.existsSync()) {
      continue;
    }
    final text = f.readAsStringSync();
    if (!text.contains('{{${entry.value}}}')) {
      done.add(entry.key); // already filled (repeated run)
      continue;
    }
    final value = appLinkValue(entry.value, config, env);
    if (value == null) {
      final msg =
          '.well-known/${entry.key}: ${entry.value} is missing (environment or configuration), file removed';
      if (strict) {
        throw PostbuildException(msg);
      }
      stderr.writeln('web_postbuild: note: $msg');
      f.deleteSync();
      continue;
    }
    f.writeAsStringSync(renderAppLinkTemplate(entry.key, text, value));
    done.add(entry.key);
  }
  return done;
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
    this.keepDebug = false,
    this.strict = false,
    this.precompress = true,
  });

  final bool strict;

  /// Step 7: put .gz/.br next to compressible files.
  final bool precompress;

  final bool keepDebug;
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

/// Default Flutter files that this bootstrap does not use: flutter.js is contained in
/// the bootstrap, flutter_service_worker.js is replaced by web/sw.js.
bool _isFlutterDefaultLeftover(String rel) =>
    rel == 'flutter.js' ||
    rel == 'flutter_service_worker.js' ||
    rel == '.last_build_id';

List<File> _filesIn(Directory dir) =>
    dir.listSync(recursive: true).whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

const Set<String> _textExt = <String>{
  'html',
  'txt',
  'xml',
  'js',
  'json',
  'webmanifest',
  'conf',
  'yml',
  'yaml',
};

bool _isText(String path) {
  final name = path.split('/').last;
  if (name == '_headers' || name == '_redirects' || name == '.htaccess') {
    return true;
  }
  final dot = name.lastIndexOf('.');
  return dot >= 0 && _textExt.contains(name.substring(dot + 1));
}

/// Are Noto fallback fonts (.woff2) present under assets/fonts/fallback/?
bool hasFontFallback(Directory web) {
  final dir = Directory('${web.path}/assets/fonts/fallback');
  return dir.existsSync() &&
      dir
          .listSync(recursive: true)
          .any((e) => e is File && e.path.endsWith('.woff2'));
}

final RegExp _revisionDirName = RegExp(r'^[0-9a-f]{40}$');

/// Moves the content of `canvaskit/` to `canvaskit/<revision>/`.
///
/// Idempotent: folders with a 40-character hex name count as already moved.
/// The one for the current revision stays, older revisions are removed. If,
/// after another flutter build web, fresh files lie directly in canvaskit/,
/// they replace those of the same name under `canvaskit/<revision>/` (no nesting).
void relocateCanvasKit(Directory web, String revision) {
  final canvasKit = Directory('${web.path}/canvaskit');
  if (!canvasKit.existsSync()) {
    return;
  }
  final target = Directory('${canvasKit.path}/$revision')
    ..createSync(recursive: true);
  for (final e in canvasKit.listSync()) {
    final name = _rel(canvasKit, e);
    if (_revisionDirName.hasMatch(name) && e is Directory) {
      if (name != revision) {
        e.deleteSync(recursive: true);
      }
      continue;
    }
    final dst = '${target.path}/$name';
    if (FileSystemEntity.typeSync(dst) != FileSystemEntityType.notFound) {
      Directory(dst).existsSync()
          ? Directory(dst).deleteSync(recursive: true)
          : File(dst).deleteSync();
    }
    e.renameSync(dst);
  }
}

/// Runs all steps; returns the written hosting files (relative).
List<String> runPostbuild(PostbuildOptions o) {
  final web = o.webDir;
  if (!web.existsSync()) {
    throw PostbuildException(
      '${web.path} does not exist (run flutter build web first)',
    );
  }
  final bootstrapFile = File('${web.path}/flutter_bootstrap.js');
  if (!bootstrapFile.existsSync()) {
    throw PostbuildException('flutter_bootstrap.js is missing');
  }

  // 0. Placeholders in security.txt (contact) must not go live.
  final securityTxt = File('${web.path}/.well-known/security.txt');
  if (securityTxt.existsSync() &&
      securityTxt.readAsStringSync().contains('{{')) {
    const msg =
        '.well-known/security.txt still contains placeholders ({{...}}), enter the contact';
    if (o.strict) {
      throw PostbuildException(msg);
    }
    stderr.writeln('web_postbuild: note: $msg');
  }

  // 0b. Fallback fonts: without Noto files under assets/fonts/fallback/
  // the app shows emoji, Cyrillic and CJK as boxes. Flutter itself only puts
  // Roboto-Regular.ttf there, so only .woff2 files count.
  if (!hasFontFallback(web)) {
    const msg =
        'no fallback fonts under assets/fonts/fallback/ (run dart run tool/fetch_font_fallback.dart build/web first)';
    if (o.strict) {
      throw PostbuildException(msg);
    }
    stderr.writeln('web_postbuild: note: $msg');
  }

  // 0c. Fallback fonts only with license text (OFL 1.1 requires it on redistribution).
  if (hasFontFallback(web) &&
      !File('${web.path}/assets/fonts/fallback/OFL.txt').existsSync()) {
    throw PostbuildException(
      'assets/fonts/fallback/OFL.txt is missing (run fetch_font_fallback.dart again)',
    );
  }

  // 0d. Fill or remove app links (.well-known).
  renderAppLinks(web, o.config, strict: o.strict);

  // 1. Rename main.dart.*. Idempotent: if the bootstrap has already been edited
  // (marker replaced) and there is no new main.dart.*, step 1 is skipped.
  final bootstrap = bootstrapFile.readAsStringSync();
  final revMatch = RegExp(r'"engineRevision":"([0-9a-f]{40})"')
      .firstMatch(bootstrap);
  if (revMatch == null) {
    throw PostbuildException('engineRevision not found');
  }
  final revision = revMatch.group(1)!;
  final mains = <String>[
    for (final ext in <String>['js', 'wasm', 'mjs'])
      if (File('${web.path}/main.dart.$ext').existsSync()) ext,
  ];
  if (!bootstrap.contains(canvasKitMarker)) {
    if (mains.isNotEmpty) {
      throw PostbuildException(
        'main.dart.* is new, but flutter_bootstrap.js has already been edited '
        '(delete build/web and rebuild)',
      );
    }
    if (!bootstrap.contains("canvasKitBaseUrl = 'canvaskit/$revision/'")) {
      throw PostbuildException(
        'Marker $canvasKitMarker is missing: web/flutter_bootstrap.js must be the custom template',
      );
    }
    stdout.writeln('web_postbuild: rename already done, only follow-up steps');
  } else {
    if (mains.isEmpty) {
      throw PostbuildException('no main.dart.* found');
    }
    final renamed = <String, String>{};
    for (final ext in mains) {
      final f = File('${web.path}/main.dart.$ext');
      final hash = sha256Hex(f.readAsBytesSync()).substring(0, 8);
      final name = 'main.$hash.dart.$ext';
      final dst = File('${web.path}/$name');
      if (dst.existsSync()) {
        dst.deleteSync();
      }
      f.renameSync(dst.path);
      renamed['main.dart.$ext'] = name;
    }
    // Leftovers of earlier builds in the same output (without rm -rf build/web).
    for (final f in web.listSync().whereType<File>()) {
      final name = _rel(web, f);
      if (RegExp(r'^main\.[0-9a-f]{8}\.dart\.(js|wasm|mjs)$').hasMatch(name) &&
          !renamed.containsValue(name)) {
        f.deleteSync();
      }
    }
    bootstrapFile.writeAsStringSync(
      rewriteBootstrap(
        bootstrap,
        renamedMain: renamed,
        engineRevision: revision,
      ),
    );
  }

  // 2. canvaskit/ -> canvaskit/<revision>/
  relocateCanvasKit(web, revision);

  // 3. Platzhalter
  final baseUrl =
      o.baseUrl ?? (o.config['WEB_BASE_URL'] as String?) ?? defaultBaseUrl;
  final gsc = o.gsc ?? (o.config['GSC_VERIFICATION'] as String?) ?? '';
  for (final name in <String>[
    'index.html',
    'sitemap.xml',
    'robots.txt',
    'llms.txt',
    'manifest.webmanifest',
  ]) {
    final f = File('${web.path}/$name');
    if (!f.existsSync()) {
      continue;
    }
    var text = rewriteBaseUrl(f.readAsStringSync(), baseUrl);
    if (name == 'index.html') {
      text = renderModulePreload(text, _mainModuleName(web));
      text = renderGscVerification(text, gsc);
      text = text.replaceAll(
        copyrightYearsPlaceholder,
        copyrightYears(buildDate()),
      );
    }
    if (name == 'sitemap.xml') {
      text = renderSitemapLastmod(text, buildDate());
    }
    f.writeAsStringSync(text);
  }

  // 4. Hosting files
  final extra = o.cspConnectExtra ?? deriveCspConnectExtra(o.config);
  final scriptExtra = deriveCspScriptExtra(o.config);
  final imgExtra = deriveCspImgExtra(o.config);
  final written = <String>[];
  final indexFile = File('${web.path}/index.html');
  final styleHashes = inlineStyleHashes(
    indexFile.existsSync() ? indexFile.readAsStringSync() : '',
  );
  final nonceFile = File('${web.path}/flutter_bootstrap.js');
  if (nonceFile.existsSync()) {
    final text = nonceFile.readAsStringSync();
    final fresh = newStyleNonce();
    final rendered = renderStyleNonce(text, fresh);
    if (rendered != null) {
      nonceFile.writeAsStringSync(rendered);
      styleHashes.add("'nonce-$fresh'");
    } else {
      final reused = existingStyleNonce(text);
      if (reused != null) styleHashes.add("'nonce-$reused'");
    }
  }
  String renderHosting(String text) => renderStyleHashes(
    renderCspPlaceholder(
      renderCspPlaceholder(
        renderCspPlaceholder(text, extra),
        scriptExtra,
        placeholder: cspScriptPlaceholder,
      ),
      imgExtra,
      placeholder: cspImgPlaceholder,
    ),
    styleHashes,
  );
  final deploy = Directory(o.deployDir);
  if (deploy.existsSync()) {
    if (o.targets.contains('cloudflare')) {
      for (final n in <String>['_headers', '_redirects']) {
        final src = File('${deploy.path}/cloudflare/$n');
        if (src.existsSync()) {
          File('${web.path}/$n')
              .writeAsStringSync(renderHosting(src.readAsStringSync()));
          written.add(n);
        }
      }
    }
    if (o.targets.contains('plesk')) {
      final src = File('${deploy.path}/plesk/.htaccess');
      if (src.existsSync()) {
        File('${web.path}/.htaccess')
            .writeAsStringSync(renderHosting(src.readAsStringSync()));
        written.add('.htaccess');
      }
    }
    final out = Directory(o.hostingOut);
    if (out.existsSync()) {
      out.deleteSync(recursive: true);
    }
    for (final target in <String>['nginx', 'traefik', 'plesk', 'cloudflare']) {
      final dir = Directory('${deploy.path}/$target');
      if (!dir.existsSync()) {
        continue;
      }
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

  // 5. Remove ballast
  if (!o.keepDebug) {
    for (final f in _filesIn(web)) {
      final rel = _rel(web, f);
      if (isPrunableEngineFile(rel) || _isFlutterDefaultLeftover(rel)) {
        f.deleteSync();
      }
    }
    final wp = Directory('${web.path}/canvaskit/$revision/webparagraph');
    if (wp.existsSync()) {
      wp.deleteSync(recursive: true);
    }
    bootstrapFile.writeAsStringSync(
      pruneWasmHashes(bootstrapFile.readAsStringSync()),
    );
  }

  // 6. Build ID (sw.js) and asset-manifest.txt
  final entries = <String, (String, int)>{};
  for (final f in _filesIn(web)) {
    final rel = _rel(web, f);
    if (rel == 'asset-manifest.txt' ||
        rel == 'sw.js' ||
        isPrecompressedSidecar(rel)) {
      continue;
    }
    final bytes = f.readAsBytesSync();
    entries[rel] = (sha256Hex(bytes), bytes.length);
  }
  final buildId = sha256Hex(
    utf8.encode(
      entries.entries.map((e) => '${e.key}:${e.value.$1}').join('\n'),
    ),
  ).substring(0, 12);
  final sw = File('${web.path}/sw.js');
  if (sw.existsSync()) {
    // Also on a repeated run: an already set build ID is replaced.
    final text = sw
        .readAsStringSync()
        .replaceAll(buildIdPlaceholder, buildId)
        .replaceAll(
          RegExp(r"const BUILD_ID = '[0-9a-f]{12}';"),
          "const BUILD_ID = '$buildId';",
        );
    sw.writeAsStringSync(text);
    entries['sw.js'] = (sha256Hex(utf8.encode(text)), utf8.encode(text).length);
  }
  final sorted = entries.keys.toList()..sort();
  final manifest = StringBuffer();
  for (final k in sorted) {
    manifest.writeln('${entries[k]!.$1}  ${entries[k]!.$2}  $k');
  }
  File('${web.path}/asset-manifest.txt').writeAsStringSync(manifest.toString());

  // 7. Precompress
  if (o.precompress) {
    precompressWeb(web);
  } else {
    removeSidecars(web);
  }
  return written;
}

// ---------------------------------------------------------------------------
// Preload and precompress the startup files
// ---------------------------------------------------------------------------

const String _preloadStart = '<!-- linefm:modulepreload -->';
const String _preloadEnd = '<!-- /linefm:modulepreload -->';

String? _mainModuleName(Directory web) {
  final names =
      web
          .listSync()
          .whereType<File>()
          .map((f) => _rel(web, f))
          .where((n) => RegExp(r'^main\.[0-9a-f]{8}\.dart\.mjs$').hasMatch(n))
          .toList()
        ..sort();
  return names.isEmpty ? null : names.first;
}

/// Puts a `<link rel="modulepreload">` for the hashed JS runtime before
/// `flutter_bootstrap.js`, so the browser fetches it alongside the bootstrap.
/// Idempotent: an earlier entry is replaced, and removed without a module.
/// The large Wasm file is not preloaded on purpose: first-time visitors only
/// start the engine after a gesture (flutter_bootstrap.js).
String renderModulePreload(String html, String? module) {
  final existing = RegExp(
    '[ \\t]*${RegExp.escape(_preloadStart)}.*?'
    '${RegExp.escape(_preloadEnd)}\\r?\\n',
    dotAll: true,
  );
  final out = html.replaceAll(existing, '');
  if (module == null) return out;
  final m = RegExp(r'([ \t]*)<script src="flutter_bootstrap\.js"')
      .firstMatch(out);
  if (m == null) return out;
  final indent = m.group(1)!;
  final tag =
      '$indent$_preloadStart<link rel="modulepreload" href="$module">'
      '$_preloadEnd\n';
  return out.replaceRange(m.start, m.start, tag);
}

/// Extensions worth compressing (text, Wasm, fonts, Flutter binary data).
const Set<String> _compressibleExt = <String>{
  'html',
  'js',
  'mjs',
  'wasm',
  'json',
  'css',
  'svg',
  'txt',
  'xml',
  'webmanifest',
  'ttf',
  'otf',
  'bin',
};

/// Minimum size; smaller files save less than a header costs.
const int precompressMinBytes = 1024;

bool isPrecompressedSidecar(String rel) =>
    rel.endsWith('.gz') || rel.endsWith('.br');

/// Whether [rel] gets precompressed (NOTICES has no extension).
bool isCompressible(String rel) {
  if (isPrecompressedSidecar(rel)) return false;
  final name = rel.split('/').last;
  if (name == 'NOTICES') return true;
  if (rel == 'asset-manifest.txt') return false;
  if (name.startsWith('.') || name == '_headers' || name == '_redirects') {
    return false;
  }
  final dot = name.lastIndexOf('.');
  return dot >= 0 && _compressibleExt.contains(name.substring(dot + 1));
}

/// Removes all .gz/.br files (before rewriting them or without step 7).
void removeSidecars(Directory web) {
  for (final f in _filesIn(web)) {
    if (isPrecompressedSidecar(_rel(web, f))) f.deleteSync();
  }
}

const String _brotliScript = r"""
const fs = require('fs');
const zlib = require('zlib');
const files = fs.readFileSync(process.argv[2], 'utf8').split('\n').filter(Boolean);
for (const f of files) {
  const src = fs.readFileSync(f);
  const out = zlib.brotliCompressSync(src, { params: {
    [zlib.constants.BROTLI_PARAM_QUALITY]: 11,
    [zlib.constants.BROTLI_PARAM_SIZE_HINT]: src.length,
  } });
  if (out.length < src.length) fs.writeFileSync(f + '.br', out);
}
""";

/// Brotli 11 via node (zlib), because dart:io has no Brotli and no new
/// dependency is needed this way. Returns false if node is missing or fails.
bool _brotliWithNode(List<File> files) {
  if (files.isEmpty) return true;
  final tmp = Directory.systemTemp.createTempSync('linefm_br');
  try {
    final list = File('${tmp.path}/files.txt')
      ..writeAsStringSync(files.map((f) => f.absolute.path).join('\n'));
    final script = File('${tmp.path}/brotli.cjs')
      ..writeAsStringSync(_brotliScript);
    final p = Process.runSync('node', <String>[
      script.path,
      list.path,
    ], runInShell: Platform.isWindows);
    if (p.exitCode != 0) {
      stderr.writeln('web_postbuild: node/brotli: ${p.stderr}');
    }
    return p.exitCode == 0;
  } on ProcessException {
    return false;
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

/// Writes `<file>.gz` and `<file>.br` next to every compressible file of at
/// least [precompressMinBytes], only if the result is smaller. Old sidecars
/// are removed first so a stale version is never served.
/// Returns the number of files written.
int precompressWeb(Directory web, {bool brotli = true}) {
  removeSidecars(web);
  final targets = <File>[
    for (final f in _filesIn(web))
      if (isCompressible(_rel(web, f)) && f.lengthSync() >= precompressMinBytes)
        f,
  ];
  var count = 0;
  final gzip = GZipCodec(level: 9);
  for (final f in targets) {
    final src = f.readAsBytesSync();
    final out = gzip.encode(src);
    if (out.length < src.length) {
      File('${f.path}.gz').writeAsBytesSync(out);
      count++;
    }
  }
  if (brotli) {
    if (_brotliWithNode(targets)) {
      count += targets.where((f) => File('${f.path}.br').existsSync()).length;
    } else {
      stderr.writeln(
        'web_postbuild: WARNING: node not available, no .br files (only .gz)',
      );
    }
  }
  return count;
}

Map<String, dynamic> _readConfig(String? path) {
  final candidates = <String>[?path, if (path == null) 'config/app.json'];
  for (final c in candidates) {
    final f = File(c);
    if (f.existsSync()) {
      return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    }
    if (path != null) {
      throw PostbuildException('Configuration $path not found');
    }
  }
  return <String, dynamic>{};
}

void main(List<String> args) => exitCode = runCli(args);

/// Command-line entry point; returns the exit code.
int runCli(List<String> args) {
  String? webPath,
      configPath,
      extra,
      deployDir,
      hostingOut,
      baseUrl,
      gsc,
      targets;
  var keepDebug = false;
  var strict = false;
  var precompress = true;
  for (var i = 0; i < args.length; i++) {
    String next() {
      if (i + 1 >= args.length) {
        throw PostbuildException('value for ${args[i]} is missing');
      }
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
      case '--keep-debug':
        keepDebug = true;
      case '--strict':
        strict = true;
      case '--no-precompress':
        precompress = false;
      case final a when a.startsWith('--'):
        stderr.writeln('Unknown option $a');
        return 64;
      default:
        webPath = args[i];
    }
  }
  if (webPath == null) {
    stderr.writeln(
      'Usage: dart run tool/web_postbuild.dart build/web [options]',
    );
    return 64;
  }
  try {
    final written = runPostbuild(
      PostbuildOptions(
        webDir: Directory(webPath),
        config: _readConfig(configPath),
        cspConnectExtra: extra ?? Platform.environment['CSP_CONNECT_EXTRA'],
        targets: targets == null
            ? const <String>{'cloudflare', 'plesk'}
            : targets
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty && s != 'none')
                  .toSet(),
        deployDir: deployDir ?? 'deploy',
        hostingOut: hostingOut ?? 'build/hosting',
        baseUrl: baseUrl,
        gsc: gsc,
        keepDebug: keepDebug,
        strict: strict,
        precompress: precompress,
      ),
    );
    stdout.writeln(
      'web_postbuild: done (${written.length} hosting files written)',
    );
    return 0;
  } on PostbuildException catch (e) {
    stderr.writeln(e);
    return 1;
  }
}
