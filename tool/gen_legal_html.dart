// Erzeugt aus assets/legal/{de,en}/*.json die statischen Rechtstext-Seiten
// fuer die Web-Version (Stores, Suchmaschinen).
//
// Aufruf (im Repo-Wurzelverzeichnis):
//   dart run tool/gen_legal_html.dart [--providers=umami,sentry,firebase,ga4]
//       [--values=legal_values.json] [--base-url=https://app.linefm.de]
//       [--out=web] [--strict] [--fill-assets]
//
// --providers  aktive Telemetrie-Anbieter (Bloecke mit "requires").
// --values     JSON-Objekt Platzhalter -> Wert (z. B. BETREIBER_NAME).
// --strict     Exit-Code 1, solange Pflicht-Platzhalter offen sind (leere oder
//              nur aus Leerzeichen bestehende Werte gelten als offen, nicht in
//              placeholders.json registrierte Platzhalter als Pflicht, "required_if"
//              macht optionale Angaben bei aktivem Anbieter zur Pflicht). Prueft
//              zusaetzlich [strictFiles] (Sicherheitskontakt, Barrierefreiheit,
//              Verhaltenskodex) auf offene {{...}}; die traegt der Betreiber
//              selbst im Repo ein, sie kommen nicht aus --values.
// --fill-assets setzt die Werte zusaetzlich direkt in assets/legal/**.json ein.
//
// Solange Platzhalter offen sind, setzt die Seite "noindex".
import 'dart:convert';
import 'dart:io';

/// Bekannte Anbieter-Schluessel fuer `requires`.
const Set<String> telemetryProviders = <String>{'umami', 'sentry', 'firebase'};

/// Weitere Anbieter mit eigener Einwilligung, die nicht unter `telemetry`
/// fallen: `ga4` = Reichweitenmessung mit Google (GTM/GA4, nur Web, P31).
const Set<String> knownProviders = <String>{...telemetryProviders, 'ga4'};

/// Lockeres Platzhalter-Muster, Zeichen fuer Zeichen gleich mit
/// `PLACEHOLDER_PATTERN` in tool/legal_store_check.py (ein Test vergleicht
/// beide). Erkennt neben `{{NAME}}` auch `{{ NAME }}`, `{{A-B}}`, Umlaute und
/// vollbreite Klammern (U+FF5B/U+FF5D), damit keine verschriebene Angabe
/// durch die Pruefung rutscht. Gruppe 1 ist der Name (vor dem Trimmen).
const String placeholderPattern =
    r'[{\uFF5B][ \t\u00A0\u3000]*[{\uFF5B][ \t\u00A0\u3000]*'
    r'([^{}\uFF5B\uFF5D\r\n]{1,80}?)'
    r'[ \t\u00A0\u3000]*[}\uFF5D][ \t\u00A0\u3000]*[}\uFF5D]';

final RegExp _placeholder = RegExp(placeholderPattern);

/// Name eines Treffers ohne Leerzeichen am Rand.
String _name(Match m) => m.group(1)!.trim();

/// Leer-, Trenn- und unsichtbare Formatzeichen (Unicode Zs, Cf, Whitespace).
final RegExp _invisible = RegExp(r'[\p{Cf}\p{Zs}\s]', unicode: true);

/// Hat [value] sichtbaren Inhalt (nach Entfernen von Cf/Zs/Whitespace)?
bool hasVisibleContent(String value) =>
    value.replaceAll(_invisible, '').isNotEmpty;

/// Weitere Dateien, die mit --strict keine Platzhalter mehr haben duerfen.
const List<String> strictFiles = <String>[
  'SECURITY.md',
  'CODE_OF_CONDUCT.md',
  'docs/BARRIEREFREIHEIT.md',
  'web/.well-known/security.txt',
];

/// Offene Platzhalter je Datei aus [paths] (fehlende Dateien zaehlen nicht).
Map<String, Set<String>> openPlaceholdersInFiles(Iterable<String> paths) {
  final Map<String, Set<String>> open = <String, Set<String>>{};
  for (final String path in paths) {
    final File file = File(path);
    if (!file.existsSync()) continue;
    final Set<String> found = findPlaceholders(file.readAsStringSync());
    if (found.isNotEmpty) open[path] = found;
  }
  return open;
}

/// Ist ein `requires`-Ausdruck (String oder Liste, "!x" = Negation) erfuellt?
/// Mehrere Eintraege einer Liste muessen alle gelten.
bool requirementMet(Object? requires, Set<String> providers) {
  if (requires == null) return true;
  final List<String> tokens = requires is List
      ? requires.map((Object? e) => '$e').toList()
      : <String>['$requires'];
  for (final String raw in tokens) {
    final bool negate = raw.startsWith('!');
    final String token = negate ? raw.substring(1) : raw;
    final bool active = token == 'telemetry'
        ? providers.any(telemetryProviders.contains)
        : providers.contains(token);
    if (active == negate) return false;
  }
  return true;
}

/// Nur Werte mit Inhalt: leere oder nur aus Leer- und unsichtbaren
/// Formatzeichen (Unicode Cf, Zs, z. B. U+200B, U+FEFF, U+00A0) bestehende
/// Werte zaehlen als nicht gesetzt (der Platzhalter bleibt offen und
/// markiert).
Map<String, String> nonBlankValues(Map<String, String> values) =>
    <String, String>{
      for (final MapEntry<String, String> e in values.entries)
        if (hasVisibleContent(e.value)) e.key: e.value,
    };

/// Werte aus einem dekodierten JSON-Objekt: nur nicht-leere Strings zaehlen
/// (Zahlen, null, Listen usw. bleiben offen, statt als "null" zu gelten).
Map<String, String> stringValues(Map<String, Object?> decoded) =>
    nonBlankValues(<String, String>{
      for (final MapEntry<String, Object?> e in decoded.entries)
        if (e.value is String) e.key: e.value! as String,
    });

/// Ist der Platzhalter [name] bei den aktiven [providers] Pflicht?
///
/// [registry] ist der Inhalt von placeholders.json unter "placeholders".
/// Nicht registrierte Namen sind Pflicht (Tippfehler fallen so auf).
/// `"required": false` macht eine Angabe optional, ausser `"required_if"`
/// (gleiche Syntax wie `requires`) ist mit den aktiven Anbietern erfuellt.
bool isRequiredPlaceholder(
  String name,
  Map<String, Object?> registry,
  Set<String> providers,
) {
  final Object? info = registry[name];
  if (info is! Map<String, Object?>) return true;
  if (info['required'] != false) return true;
  final Object? cond = info['required_if'];
  return cond != null && requirementMet(cond, providers);
}

/// Offene Pflicht-Platzhalter (sortiert) aus [open].
List<String> requiredOpen(
  Set<String> open,
  Map<String, Object?> registry,
  Set<String> providers,
) =>
    open
        .where((String k) => isRequiredPlaceholder(k, registry, providers))
        .toList()
      ..sort();

/// Alle Platzhalter-Namen in [text].
Set<String> findPlaceholders(String text) =>
    _placeholder.allMatches(text).map(_name).toSet();

/// Ersetzt bekannte Platzhalter; unbekannte bleiben stehen.
String substitute(String text, Map<String, String> values) =>
    text.replaceAllMapped(
      _placeholder,
      (Match m) => values[_name(m)] ?? m.group(0)!,
    );

/// Wie [substitute], aber fuer Rohtext einer JSON-Datei (Werte werden escaped).
String substituteJsonText(String raw, Map<String, String> values) =>
    raw.replaceAllMapped(_placeholder, (Match m) {
      final String? v = values[_name(m)];
      if (v == null) return m.group(0)!;
      final String encoded = jsonEncode(v);
      return encoded.substring(1, encoded.length - 1);
    });

String escapeHtml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

/// Escaped Text, wandelt "\n" in <br> und markiert offene Platzhalter.
String inlineHtml(String text, Map<String, String> values) {
  final StringBuffer out = StringBuffer();
  int last = 0;
  for (final Match m in _placeholder.allMatches(text)) {
    out.write(escapeHtml(text.substring(last, m.start)));
    final String? v = values[_name(m)];
    out.write(
      v != null
          ? escapeHtml(v)
          : '<mark class="ph">${escapeHtml(m.group(0)!)}</mark>',
    );
    last = m.end;
  }
  out.write(escapeHtml(text.substring(last)));
  return out.toString().replaceAll('\n', '<br>');
}

/// Sichtbare Bloecke eines Dokuments (requires gefiltert).
List<Map<String, Object?>> visibleBlocks(
  Map<String, Object?> doc,
  Set<String> providers,
) {
  final List<Object?> all = (doc['blocks'] as List<Object?>?) ?? <Object?>[];
  return all
      .whereType<Map<String, Object?>>()
      .where(
        (Map<String, Object?> b) => requirementMet(b['requires'], providers),
      )
      .toList();
}

/// Offene Platzhalter in den sichtbaren Bloecken.
Set<String> openPlaceholders(
  Map<String, Object?> doc,
  Set<String> providers,
  Map<String, String> values,
) {
  final Set<String> open = <String>{};
  for (final Map<String, Object?> b in visibleBlocks(doc, providers)) {
    final List<String> texts = <String>[
      '${b['text'] ?? ''}',
      '${b['address'] ?? ''}',
      '${b['url'] ?? ''}',
      ...((b['items'] as List<Object?>?) ?? <Object?>[]).map(
        (Object? e) => '$e',
      ),
    ];
    for (final String t in texts) {
      open.addAll(
        findPlaceholders(t)
            .where((String k) => (values[k] ?? '').trim().isEmpty),
      );
    }
  }
  return open;
}

const Map<String, Map<String, String>> _ui = <String, Map<String, String>>{
  'de': <String, String>{
    'home': 'Zur App',
    'imprint': 'Impressum',
    'privacy': 'Datenschutz',
    'switchLabel': 'English',
    'switchLang': 'en',
    'siteName': 'LINEFM Radio',
    'descImprint': 'Impressum der LINEFM Radio App.',
    'descPrivacy': 'Datenschutzerklärung der LINEFM Radio App.',
    'updated': 'Stand',
    'nav': 'Rechtliches',
  },
  'en': <String, String>{
    'home': 'Open the app',
    'imprint': 'Imprint',
    'privacy': 'Privacy',
    'switchLabel': 'Deutsch',
    'switchLang': 'de',
    'siteName': 'LINEFM Radio',
    'descImprint': 'Imprint of the LINEFM Radio app.',
    'descPrivacy': 'Privacy policy of the LINEFM Radio app.',
    'updated': 'As of',
    'nav': 'Legal',
  },
};

/// Pfad der Seite: de unter /KIND/, en unter /KIND/en/.
String pagePath(String kind, String lang) =>
    lang == 'de' ? '/$kind/' : '/$kind/en/';

String _blockHtml(Map<String, Object?> b, Map<String, String> values) {
  final String text = '${b['text'] ?? ''}';
  switch (b['type']) {
    case 'h1':
      return '<h1>${inlineHtml(text, values)}</h1>';
    case 'h2':
      return '<h2>${inlineHtml(text, values)}</h2>';
    case 'p':
      return '<p>${inlineHtml(text, values)}</p>';
    case 'ul':
      final String items = ((b['items'] as List<Object?>?) ?? <Object?>[])
          .map((Object? e) => '<li>${inlineHtml('$e', values)}</li>')
          .join('\n');
      return '<ul>\n$items\n</ul>';
    case 'link':
      final String url = substitute('${b['url'] ?? ''}', values).trim();
      // Nur http(s) und mailto werden zum Link (kein javascript:, data:, ...);
      // alles andere, auch ein offener Platzhalter, bleibt Text.
      if (!isSafeLinkUrl(url)) return '<p>${inlineHtml(text, values)}</p>';
      return '<p><a href="${escapeHtml(url)}" rel="noopener noreferrer">'
          '${inlineHtml(text, values)}</a></p>';
    case 'mail':
      final String address = substitute('${b['address'] ?? text}', values);
      if (_placeholder.hasMatch(address)) {
        return '<p>${inlineHtml(text, values)}</p>';
      }
      return '<p><a href="mailto:${escapeHtml(address)}">'
          '${inlineHtml(text, values)}</a></p>';
    default:
      throw FormatException('Unbekannter Blocktyp: ${b['type']}');
  }
}

/// Erlaubte Link-Ziele in Rechtstexten: absolute http(s)-Adressen mit Host
/// und mailto.
bool isSafeLinkUrl(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) return false;
  final String scheme = uri.scheme.toLowerCase();
  if (scheme == 'mailto') return uri.path.isNotEmpty;
  return (scheme == 'https' || scheme == 'http') && uri.host.isNotEmpty;
}

/// Prueft `--base-url`: absolute http(s)-Adresse ohne Anfrage und Fragment.
String checkedBaseUrl(String raw) {
  final Uri? uri = Uri.tryParse(raw.trim());
  if (uri == null ||
      !(uri.scheme == 'https' || uri.scheme == 'http') ||
      uri.host.isEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw FormatException('--base-url muss eine http(s)-Adresse sein: $raw');
  }
  return raw.trim();
}

/// Liest `--providers` und lehnt unbekannte Anbieter ab (wie
/// legal_store_check.py).
Set<String> parseProviders(String raw) {
  final Set<String> providers = raw
      .split(',')
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toSet();
  final Set<String> unknown = providers.difference(knownProviders);
  if (unknown.isNotEmpty) {
    throw FormatException(
      'unbekannte Anbieter: ${(unknown.toList()..sort()).join(", ")}',
    );
  }
  return providers;
}

/// Rendert eine komplette HTML-Seite.
String renderPage(
  Map<String, Object?> doc, {
  required String kind,
  required String lang,
  required String baseUrl,
  required Set<String> providers,
  required Map<String, String> values,
}) {
  final Map<String, String> ui = _ui[lang]!;
  final String other = ui['switchLang']!;
  final String base = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final String selfUrl = '$base${pagePath(kind, lang)}';
  final String deUrl = '$base${pagePath(kind, 'de')}';
  final String enUrl = '$base${pagePath(kind, 'en')}';
  final String switchUrl = other == 'de' ? deUrl : enUrl;
  final String css = lang == 'de' ? 'legal.css' : '../legal.css';
  final bool isDraft = openPlaceholders(doc, providers, values).isNotEmpty;
  final String title = '${doc['title']}';
  final String desc = ui[kind == 'impressum' ? 'descImprint' : 'descPrivacy']!;
  final String body = visibleBlocks(
    doc,
    providers,
  ).map((Map<String, Object?> b) => _blockHtml(b, values)).join('\n');
  final String updated = '${doc['updated'] ?? ''}';

  return '''<!doctype html>
<html lang="$lang">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)} | ${ui['siteName']}</title>
<meta name="description" content="${escapeHtml(desc)}">
<meta name="robots" content="${isDraft ? 'noindex, nofollow' : 'index, follow'}">
<meta name="theme-color" content="#0f1221">
<meta name="color-scheme" content="dark light">
<link rel="canonical" href="${escapeHtml(selfUrl)}">
<link rel="alternate" hreflang="de" href="${escapeHtml(deUrl)}">
<link rel="alternate" hreflang="en" href="${escapeHtml(enUrl)}">
<link rel="alternate" hreflang="x-default" href="${escapeHtml(deUrl)}">
<link rel="stylesheet" href="$css">
</head>
<body>
<!-- ENTWURF: Rechtstext muss vor Veroeffentlichung anwaltlich geprueft werden. -->
<header class="site-header">
<a class="brand" href="${escapeHtml(base)}/">${ui['siteName']}</a>
<nav aria-label="${ui['nav']}">
<a href="${pagePath('impressum', lang)}"${kind == 'impressum' ? ' aria-current="page"' : ''}>${ui['imprint']}</a>
<a href="${pagePath('datenschutz', lang)}"${kind == 'datenschutz' ? ' aria-current="page"' : ''}>${ui['privacy']}</a>
<a href="${escapeHtml(switchUrl)}" hreflang="$other" lang="$other">${ui['switchLabel']}</a>
</nav>
</header>
<main>
$body
<p class="meta">${ui['updated']}: ${escapeHtml(updated)}</p>
<p><a href="${escapeHtml(base)}/">${ui['home']}</a></p>
</main>
</body>
</html>
''';
}

/// Gemeinsames Stylesheet (dunkel wie die App, hell bei Systemeinstellung).
const String legalCss =
    '''/* Erzeugt von tool/gen_legal_html.dart, nicht von Hand aendern. */
:root {
  color-scheme: dark light;
  --bg: #0f1221;
  --text: #ffffff;
  --muted: #a4a7b6;
  --line: rgba(255, 255, 255, 0.12);
  --link: #ffffff;
  --mark: #ff7a93;
}
@media (prefers-color-scheme: light) {
  :root {
    --bg: #f4f5fa;
    --text: #0f1221;
    --muted: #4a4e62;
    --line: rgba(15, 18, 33, 0.14);
    --link: #0f1221;
    --mark: #9b0025;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font: 16px/1.65 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
}
.site-header, main { max-width: 46rem; margin: 0 auto; padding: 0 16px; }
.site-header {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 24px;
  align-items: center;
  justify-content: space-between;
  padding-top: 20px;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--line);
}
.brand { font-weight: 700; letter-spacing: 0.12em; text-transform: uppercase; text-decoration: none; }
.site-header nav { display: flex; flex-wrap: wrap; gap: 4px 20px; }
a { color: var(--link); text-underline-offset: 3px; }
a:focus-visible { outline: 2px solid var(--link); outline-offset: 3px; }
a[aria-current="page"] { font-weight: 700; }
main { padding-top: 24px; padding-bottom: 64px; }
h1 { font-size: 1.9rem; line-height: 1.2; margin: 0 0 16px; }
h2 { font-size: 1.2rem; margin: 32px 0 8px; }
p, ul { margin: 0 0 14px; }
ul { padding-left: 1.3rem; }
.meta { color: var(--muted); margin-top: 32px; }
mark.ph { background: transparent; color: var(--mark); font-weight: 700; }
''';

Map<String, String> _loadValues(String? path) {
  if (path == null) return <String, String>{};
  final Object? decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('--values muss ein JSON-Objekt sein.');
  }
  return stringValues(decoded);
}

String? _arg(List<String> args, String name) {
  for (final String a in args) {
    if (a.startsWith('--$name=')) return a.substring(name.length + 3);
  }
  return null;
}

Map<String, Object?> _readDoc(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

void _write(String path, String content) {
  final File f = File(path)..createSync(recursive: true);
  f.writeAsStringSync(content);
}

Future<void> main(List<String> args) async {
  final Set<String> providers;
  final String baseUrl;
  try {
    providers = parseProviders(_arg(args, 'providers') ?? '');
    baseUrl = checkedBaseUrl(_arg(args, 'base-url') ?? 'https://app.linefm.de');
  } on FormatException catch (e) {
    stderr.writeln('FEHLER: ${e.message}');
    exitCode = 2;
    return;
  }
  final String out = _arg(args, 'out') ?? 'web';
  final Map<String, String> values = nonBlankValues(
    _loadValues(_arg(args, 'values')),
  );
  final bool strict = args.contains('--strict');

  final Object? meta = jsonDecode(
    File('assets/legal/placeholders.json').readAsStringSync(),
  );
  final Map<String, Object?> required =
      ((meta! as Map<String, Object?>)['placeholders']!
          as Map<String, Object?>);

  final Set<String> allOpen = <String>{};
  for (final String kind in <String>['impressum', 'datenschutz']) {
    for (final String lang in <String>['de', 'en']) {
      final Map<String, Object?> doc = _readDoc(
        'assets/legal/$lang/$kind.json',
      );
      allOpen.addAll(openPlaceholders(doc, providers, values));
      final String dir = lang == 'de' ? '$out/$kind' : '$out/$kind/en';
      _write(
        '$dir/index.html',
        renderPage(
          doc,
          kind: kind,
          lang: lang,
          baseUrl: baseUrl,
          providers: providers,
          values: values,
        ),
      );
    }
    _write('$out/$kind/legal.css', legalCss);
  }

  if (args.contains('--fill-assets')) {
    for (final String lang in <String>['de', 'en']) {
      for (final String kind in <String>['impressum', 'datenschutz']) {
        final File f = File('assets/legal/$lang/$kind.json');
        f.writeAsStringSync(substituteJsonText(f.readAsStringSync(), values));
      }
    }
  }

  final List<String> openRequired = requiredOpen(allOpen, required, providers);
  stdout.writeln(
    'Seiten geschrieben nach $out/ (Anbieter: ${providers.isEmpty ? "keine" : providers.join(", ")}).',
  );
  if (allOpen.isNotEmpty) {
    stdout.writeln(
      'Offene Platzhalter (${allOpen.length}): ${(allOpen.toList()..sort()).join(", ")}',
    );
    stdout.writeln(
      'Seiten tragen noindex, bis alle Platzhalter gefuellt sind.',
    );
  }
  if (strict && openRequired.isNotEmpty) {
    stderr.writeln(
      'FEHLER (--strict): Pflichtangaben fehlen: ${openRequired.join(", ")}',
    );
    exitCode = 1;
  }
  if (strict) {
    final Map<String, Set<String>> files = openPlaceholdersInFiles(strictFiles);
    for (final MapEntry<String, Set<String>> e in files.entries) {
      stderr.writeln(
        'FEHLER (--strict): ${e.key} enthaelt noch Platzhalter: '
        '${(e.value.toList()..sort()).join(", ")}',
      );
      exitCode = 1;
    }
  }
}
