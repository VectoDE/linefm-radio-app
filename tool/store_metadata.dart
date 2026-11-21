// Erzeugt und prueft die fastlane-kompatible Metadaten-Struktur unter
// fastlane/metadata/ aus docs/STORE-TEXTE.md.
//
// Einzige Quelle der Wahrheit ist docs/STORE-TEXTE.md (dort liest und
// genehmigt jaybelife die Texte). Die Dateien unter fastlane/metadata/ sind
// abgeleitet und werden nie von Hand bearbeitet. fastlane selbst ist nicht
// installiert, die Struktur folgt nur dessen Dateinamen (supply fuer Google
// Play, deliver fuer den App Store).
//
// Aufruf (im Repo-Wurzelverzeichnis):
//   dart tool/store_metadata.dart            Pruefen (Standard)
//   dart tool/store_metadata.dart --check    wie oben
//   dart tool/store_metadata.dart --write    Dateien neu erzeugen
//
// Pruefen heisst: Zeichenlimits eingehalten, Deutsch und Englisch vollstaendig,
// jede Datei gleich dem Text aus STORE-TEXTE.md, keine unbekannten Dateien.
//
// Limits (Stand der Abfrage 21.11.2026):
//   Google Play: Titel 30, Kurzbeschreibung 80, Beschreibung 4000 Zeichen
//     (https://support.google.com/googleplay/android-developer/answer/9859152),
//     Neuerungen 500 Zeichen je Sprache
//     (https://support.google.com/googleplay/android-developer/answer/9859348).
//   App Store: Name 30 und Untertitel 30 Zeichen
//     (https://developer.apple.com/help/app-store-connect/reference/app-information/app-information),
//     Beschreibung 4000 Zeichen, Schluesselwoerter 100 Bytes, Neuerungen 4000
//     Zeichen
//     (https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).
import 'dart:convert';
import 'dart:io';

/// Eine Datei, die fastlane erwartet, samt Limit.
class MetadataField {
  const MetadataField(
    this.file,
    this.labels, {
    this.maxChars,
    this.maxBytes,
    this.required = true,
  });

  /// Pfad relativ zum Sprachordner.
  final String file;

  /// Fettgedruckte Bezeichnungen in STORE-TEXTE.md (deutsch und englisch).
  final Set<String> labels;
  final int? maxChars;
  final int? maxBytes;
  final bool required;
}

/// Abschnitt in STORE-TEXTE.md mit Zielordner.
class MetadataTarget {
  const MetadataTarget(this.heading, this.outDir, this.fields);

  /// Text der `##`-Ueberschrift (Anfang genuegt).
  final String heading;

  /// Ordner unter fastlane/metadata/, `{locale}` wird ersetzt.
  final String outDir;
  final List<MetadataField> fields;
}

const Map<String, String> locales = <String, String>{
  'Deutsch': 'de-DE',
  'English': 'en-US',
};

const List<MetadataTarget> targets = <MetadataTarget>[
  MetadataTarget('Google Play', 'android/{locale}', <MetadataField>[
    MetadataField('title.txt', <String>{'Titel', 'Title'}, maxChars: 30),
    MetadataField('short_description.txt', <String>{
      'Kurzbeschreibung',
      'Short description',
    }, maxChars: 80),
    MetadataField('full_description.txt', <String>{
      'Beschreibung',
      'Description',
    }, maxChars: 4000),
    MetadataField('changelogs/default.txt', <String>{
      'Neuerungen',
      "What's new",
    }, maxChars: 500),
  ]),
  MetadataTarget('App Store (Apple', '{locale}', <MetadataField>[
    MetadataField('name.txt', <String>{'Name'}, maxChars: 30),
    MetadataField('subtitle.txt', <String>{
      'Untertitel',
      'Subtitle',
    }, maxChars: 30),
    MetadataField('description.txt', <String>{
      'Beschreibung',
      'Description',
    }, maxChars: 4000),
    MetadataField('keywords.txt', <String>{
      'Schlüsselwörter',
      'Keywords',
    }, maxBytes: 100),
    MetadataField('release_notes.txt', <String>{
      'Neu in dieser Version',
      "What's new",
    }, maxChars: 4000),
    MetadataField('privacy_url.txt', <String>{
      'Datenschutz-URL',
      'Privacy URL',
    }, maxChars: 255),
    MetadataField('support_url.txt', <String>{
      'Support-URL',
      'Support URL',
    }, maxChars: 255),
    MetadataField('marketing_url.txt', <String>{
      'Marketing-URL',
      'Marketing URL',
    }, maxChars: 255),
  ]),
];

/// Liest STORE-TEXTE.md und liefert Pfad (relativ zu fastlane/metadata) ->
/// Inhalt. Wirft [FormatException], wenn ein Abschnitt oder Feld fehlt.
Map<String, String> parseStoreTexts(String markdown) {
  final List<String> lines = const LineSplitter().convert(markdown);
  final Map<String, String> out = <String, String>{};
  for (final MetadataTarget target in targets) {
    final int start = lines.indexWhere(
      (String l) => l.startsWith('## ${target.heading}'),
    );
    if (start < 0) {
      throw FormatException('Abschnitt "## ${target.heading}" fehlt');
    }
    int end = lines.length;
    for (int i = start + 1; i < lines.length; i++) {
      if (lines[i].startsWith('## ') || lines[i] == '---') {
        end = i;
        break;
      }
    }
    String? lang;
    String? label;
    final List<String> quote = <String>[];
    final Map<String, Map<String, String>> found =
        <String, Map<String, String>>{};

    void flush() {
      if (lang != null && label != null && quote.isNotEmpty) {
        found.putIfAbsent(lang, () => <String, String>{})[label] = quote
            .join('\n')
            .trim();
      }
      quote.clear();
    }

    for (int i = start + 1; i < end; i++) {
      final String line = lines[i];
      if (line.startsWith('### ')) {
        flush();
        lang = line.substring(4).trim();
        label = null;
      } else if (line.startsWith('**')) {
        flush();
        final Match? m = RegExp(r'^\*\*(.+?)\*\*').firstMatch(line);
        label = m?.group(1);
      } else if (line.startsWith('>')) {
        quote.add(line.replaceFirst(RegExp(r'^> ?'), ''));
      } else if (line.trim().isEmpty) {
        continue;
      } else {
        // Fliesstext zwischen den Feldern beendet ein laufendes Zitat nicht.
        continue;
      }
    }
    flush();

    for (final MapEntry<String, String> loc in locales.entries) {
      final Map<String, String>? fields = found[loc.key];
      if (fields == null) {
        throw FormatException(
          'Abschnitt "${target.heading}": Sprache "${loc.key}" fehlt',
        );
      }
      for (final MetadataField f in target.fields) {
        String? key;
        for (final String candidate in f.labels) {
          if (fields.containsKey(candidate)) key = candidate;
        }
        if (key == null) {
          if (f.required) {
            throw FormatException(
              'Abschnitt "${target.heading}", ${loc.key}: Feld '
              '"${f.labels.first}" fehlt',
            );
          }
          continue;
        }
        final String dir = target.outDir.replaceAll('{locale}', loc.value);
        out['$dir/${f.file}'] = '${fields[key]!}\n';
      }
    }
  }
  return out;
}

/// Zaehlt Unicode-Zeichen (Code Points), nicht UTF-16-Einheiten.
int charCount(String s) => s.runes.length;

/// Prueft Limits der abgeleiteten Dateien. Liefert Fehlermeldungen.
List<String> checkLimits(Map<String, String> files) {
  final List<String> problems = <String>[];
  for (final MetadataTarget target in targets) {
    for (final MapEntry<String, String> loc in locales.entries) {
      final String dir = target.outDir.replaceAll('{locale}', loc.value);
      for (final MetadataField f in target.fields) {
        final String path = '$dir/${f.file}';
        final String? raw = files[path];
        if (raw == null) {
          if (f.required) problems.add('$path fehlt');
          continue;
        }
        final String text = raw.trim();
        if (text.isEmpty) problems.add('$path ist leer');
        if (f.maxChars != null && charCount(text) > f.maxChars!) {
          problems.add(
            '$path hat ${charCount(text)} Zeichen, erlaubt sind ${f.maxChars}',
          );
        }
        if (f.maxBytes != null && utf8.encode(text).length > f.maxBytes!) {
          problems.add(
            '$path hat ${utf8.encode(text).length} Bytes, erlaubt sind '
            '${f.maxBytes}',
          );
        }
        if (f.file.endsWith('_url.txt') &&
            !RegExp(r'^https://\S+$').hasMatch(text)) {
          problems.add('$path ist keine https-Adresse ohne Leerzeichen');
        }
        if (f.file == 'keywords.txt' &&
            (text.contains(', ') ||
                text.endsWith(',') ||
                text.contains(',,'))) {
          problems.add(
            '$path: Schluesselwoerter mit Komma trennen, ohne Leerzeichen, '
            'ohne Komma am Ende',
          );
        }
        if (RegExp(r'\{\{.*?\}\}').hasMatch(text)) {
          problems.add('$path enthaelt einen offenen Platzhalter');
        }
      }
    }
  }
  return problems;
}

/// Prueft, ob die in STORE-TEXTE.md genannten Zeichenzahlen stimmen, etwa
/// "(12 von 30 Zeichen)" oder "(1158 of 4000 characters)".
List<String> checkStatedCounts(String markdown, Map<String, String> files) {
  final List<String> problems = <String>[];
  final List<String> lines = const LineSplitter().convert(markdown);
  for (final MetadataTarget target in targets) {
    final int start = lines.indexWhere(
      (String l) => l.startsWith('## ${target.heading}'),
    );
    String? lang;
    for (int i = start + 1; i < lines.length; i++) {
      final String line = lines[i];
      if (line.startsWith('## ') || line == '---') break;
      if (line.startsWith('### ')) lang = line.substring(4).trim();
      final Match? m = RegExp(
        r'^\*\*(.+?)\*\* \((\d+) (?:von|of) \d+ (?:Zeichen|characters)\)',
      ).firstMatch(line);
      if (m == null || lang == null || !locales.containsKey(lang)) continue;
      for (final MetadataField f in target.fields) {
        if (!f.labels.contains(m.group(1))) continue;
        final String dir = target.outDir.replaceAll('{locale}', locales[lang]!);
        final String? text = files['$dir/${f.file}'];
        if (text == null) continue;
        final int actual = charCount(text.trim());
        if (actual != int.parse(m.group(2)!)) {
          problems.add(
            'STORE-TEXTE.md ($lang, ${m.group(1)}): nennt ${m.group(2)} '
            'Zeichen, gezaehlt $actual',
          );
        }
      }
    }
  }
  return problems;
}

/// Liest alle Textdateien unter [metadataDir] (Pfad relativ, mit `/`).
Map<String, String> readMetadataDir(Directory metadataDir) {
  final Map<String, String> out = <String, String>{};
  if (!metadataDir.existsSync()) return out;
  for (final FileSystemEntity e in metadataDir.listSync(recursive: true)) {
    if (e is! File) continue;
    final String rel = e.path
        .substring(metadataDir.path.length)
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/'), '');
    out[rel] = e.readAsStringSync().replaceAll('\r\n', '\n');
  }
  return out;
}

/// Vergleicht Soll (aus STORE-TEXTE.md) und Ist (auf der Platte).
List<String> checkInSync(
  Map<String, String> expected,
  Map<String, String> actual,
) {
  final List<String> problems = <String>[];
  for (final MapEntry<String, String> e in expected.entries) {
    final String? have = actual[e.key];
    if (have == null) {
      problems.add('fastlane/metadata/${e.key} fehlt');
    } else if (have != e.value) {
      problems.add('fastlane/metadata/${e.key} weicht von STORE-TEXTE.md ab');
    }
  }
  for (final String k in actual.keys) {
    if (!expected.containsKey(k)) {
      problems.add(
        'fastlane/metadata/$k ist unbekannt (nicht in STORE-TEXTE.md)',
      );
    }
  }
  return problems;
}

/// Gesamtpruefung fuer das Repo unter [root].
List<String> checkRepo(String root) {
  final String md = File('$root/docs/STORE-TEXTE.md').readAsStringSync();
  final Map<String, String> expected;
  try {
    expected = parseStoreTexts(md.replaceAll('\r\n', '\n'));
  } on FormatException catch (e) {
    return <String>['STORE-TEXTE.md: ${e.message}'];
  }
  return <String>[
    ...checkLimits(expected),
    ...checkStatedCounts(md.replaceAll('\r\n', '\n'), expected),
    ...checkInSync(
      expected,
      readMetadataDir(Directory('$root/fastlane/metadata')),
    ),
  ];
}

void main(List<String> args) {
  final bool write = args.contains('--write');
  const String root = '.';
  if (write) {
    final String md = File('$root/docs/STORE-TEXTE.md')
        .readAsStringSync()
        .replaceAll('\r\n', '\n');
    final Map<String, String> expected = parseStoreTexts(md);
    final List<String> limits = checkLimits(expected);
    if (limits.isNotEmpty) {
      limits.forEach(stderr.writeln);
      exitCode = 1;
      return;
    }
    final Directory dir = Directory('$root/fastlane/metadata');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    for (final MapEntry<String, String> e in expected.entries) {
      File('${dir.path}/${e.key}')
        ..createSync(recursive: true)
        ..writeAsStringSync(e.value);
    }
    stdout.writeln('${expected.length} Dateien nach ${dir.path} geschrieben.');
    return;
  }
  final List<String> problems = checkRepo(root);
  if (problems.isEmpty) {
    stdout.writeln('Store-Metadaten in Ordnung.');
    return;
  }
  problems.forEach(stderr.writeln);
  exitCode = 1;
}
