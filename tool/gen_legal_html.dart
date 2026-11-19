// Erzeugt aus assets/legal/{de,en}/*.json die statischen Rechtstext-Seiten
// fuer die Web-Version (Stores, Suchmaschinen).
//
// Aufruf (im Repo-Wurzelverzeichnis):
//   dart run tool/gen_legal_html.dart [--providers=umami,sentry,firebase]
//       [--values=legal_values.json] [--base-url=https://app.linefm.de]
//       [--out=web] [--strict] [--fill-assets]
//
// --providers  aktive Telemetrie-Anbieter (Bloecke mit "requires").
// --values     JSON-Objekt Platzhalter -> Wert (z. B. BETREIBER_NAME).
// --strict     Exit-Code 1, solange Pflicht-Platzhalter offen sind. Prueft
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

final RegExp _placeholder = RegExp(r'\{\{(\w+)\}\}');

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

/// Alle Platzhalter-Namen in [text].
Set<String> findPlaceholders(String text) =>
    _placeholder.allMatches(text).map((Match m) => m.group(1)!).toSet();

/// Ersetzt bekannte Platzhalter; unbekannte bleiben stehen.
String substitute(String text, Map<String, String> values) =>
    text.replaceAllMapped(
      _placeholder,
      (Match m) => values[m.group(1)] ?? m.group(0)!,
    );

/// Wie [substitute], aber fuer Rohtext einer JSON-Datei (Werte werden escaped).
String substituteJsonText(String raw, Map<String, String> values) =>
    raw.replaceAllMapped(_placeholder, (Match m) {
      final String? v = values[m.group(1)];
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
    final String? v = values[m.group(1)];
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
        findPlaceholders(t).where((String k) => !values.containsKey(k)),
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
      final String url = substitute('${b['url'] ?? ''}', values);
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
<a class="brand" href="$base/">${ui['siteName']}</a>
<nav aria-label="${ui['nav']}">
<a href="${pagePath('impressum', lang)}"${kind == 'impressum' ? ' aria-current="page"' : ''}>${ui['imprint']}</a>
<a href="${pagePath('datenschutz', lang)}"${kind == 'datenschutz' ? ' aria-current="page"' : ''}>${ui['privacy']}</a>
<a href="${escapeHtml(switchUrl)}" hreflang="$other" lang="$other">${ui['switchLabel']}</a>
</nav>
</header>
<main>
$body
<p class="meta">${ui['updated']}: ${escapeHtml(updated)}</p>
<p><a href="$base/">${ui['home']}</a></p>
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
  --mark: #ff4b6e;
}
@media (prefers-color-scheme: light) {
  :root {
    --bg: #f4f5fa;
    --text: #0f1221;
    --muted: #4a4e62;
    --line: rgba(15, 18, 33, 0.14);
    --link: #0f1221;
    --mark: #b3002b;
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
  return decoded.map(
    (String k, Object? v) => MapEntry<String, String>(k, '$v'),
  );
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
  final Set<String> providers = (_arg(args, 'providers') ?? '')
      .split(',')
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toSet();
  final String baseUrl = _arg(args, 'base-url') ?? 'https://app.linefm.de';
  final String out = _arg(args, 'out') ?? 'web';
  final Map<String, String> values = _loadValues(_arg(args, 'values'));
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

  final List<String> openRequired =
      allOpen
          .where(
            (String k) =>
                (required[k] as Map<String, Object?>?)?['required'] != false,
          )
          .toList()
        ..sort();
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
