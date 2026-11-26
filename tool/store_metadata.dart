// Generates and checks the fastlane-compatible metadata structure under
// fastlane/metadata/ from docs/STORE-TEXTE.md.
//
// The single source of truth is docs/STORE-TEXTE.md (that is where
// LineFM Studios reads and approves the texts). The files under fastlane/metadata/ are
// derived and are never edited by hand. fastlane itself is not
// installed, the structure only follows its file names (supply for Google
// Play, deliver for the App Store).
//
// Usage (in the repo root):
//   dart tool/store_metadata.dart            check (default)
//   dart tool/store_metadata.dart --check    same as above
//   dart tool/store_metadata.dart --write    regenerate the files
//
// Checking means: character limits met, German and English complete,
// every file equal to the text from STORE-TEXTE.md, no unknown files.
//
// Limits (as queried on 2026-11-21):
//   Google Play: title 30, short description 80, description 4000 characters
//     (https://support.google.com/googleplay/android-developer/answer/9859152),
//     what's new 500 characters per language
//     (https://support.google.com/googleplay/android-developer/answer/9859348).
//   App Store: name 30 and subtitle 30 characters
//     (https://developer.apple.com/help/app-store-connect/reference/app-information/app-information),
//     description 4000 characters, keywords 100 bytes, what's new 4000
//     characters
//     (https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).
import 'dart:convert';
import 'dart:io';

/// A file that fastlane expects, including its limit.
class MetadataField {
  const MetadataField(
    this.file,
    this.labels, {
    this.maxChars,
    this.maxBytes,
    this.required = true,
  });

  /// Path relative to the language folder.
  final String file;

  /// Bold labels in STORE-TEXTE.md (German and English).
  final Set<String> labels;
  final int? maxChars;
  final int? maxBytes;
  final bool required;
}

/// Section in STORE-TEXTE.md with target folder.
class MetadataTarget {
  const MetadataTarget(this.heading, this.outDir, this.fields);

  /// Text of the `##` heading (the beginning is enough).
  final String heading;

  /// Folder under fastlane/metadata/, `{locale}` is replaced.
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

/// Reads STORE-TEXTE.md and returns path (relative to fastlane/metadata) ->
/// content. Throws [FormatException] if a section or field is missing.
Map<String, String> parseStoreTexts(String markdown) {
  final List<String> lines = const LineSplitter().convert(markdown);
  final Map<String, String> out = <String, String>{};
  for (final MetadataTarget target in targets) {
    final int start = lines.indexWhere(
      (String l) => l.startsWith('## ${target.heading}'),
    );
    if (start < 0) {
      throw FormatException('Section "## ${target.heading}" is missing');
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
        // Running text between the fields does not end an ongoing quote.
        continue;
      }
    }
    flush();

    for (final MapEntry<String, String> loc in locales.entries) {
      final Map<String, String>? fields = found[loc.key];
      if (fields == null) {
        throw FormatException(
          'Section "${target.heading}": language "${loc.key}" is missing',
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
              'Section "${target.heading}", ${loc.key}: field '
              '"${f.labels.first}" is missing',
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

/// Counts Unicode characters (code points), not UTF-16 units.
int charCount(String s) => s.runes.length;

/// Checks limits of the derived files. Returns error messages.
List<String> checkLimits(Map<String, String> files) {
  final List<String> problems = <String>[];
  for (final MetadataTarget target in targets) {
    for (final MapEntry<String, String> loc in locales.entries) {
      final String dir = target.outDir.replaceAll('{locale}', loc.value);
      for (final MetadataField f in target.fields) {
        final String path = '$dir/${f.file}';
        final String? raw = files[path];
        if (raw == null) {
          if (f.required) problems.add('$path is missing');
          continue;
        }
        final String text = raw.trim();
        if (text.isEmpty) problems.add('$path is empty');
        if (f.maxChars != null && charCount(text) > f.maxChars!) {
          problems.add(
            '$path has ${charCount(text)} characters, allowed are ${f.maxChars}',
          );
        }
        if (f.maxBytes != null && utf8.encode(text).length > f.maxBytes!) {
          problems.add(
            '$path has ${utf8.encode(text).length} bytes, allowed are '
            '${f.maxBytes}',
          );
        }
        if (f.file.endsWith('_url.txt') &&
            !RegExp(r'^https://\S+$').hasMatch(text)) {
          problems.add('$path is not an https address without spaces');
        }
        if (f.file == 'keywords.txt' &&
            (text.contains(', ') ||
                text.endsWith(',') ||
                text.contains(',,'))) {
          problems.add(
            '$path: separate keywords with a comma, without spaces, '
            'without a trailing comma',
          );
        }
        if (RegExp(r'\{\{.*?\}\}').hasMatch(text)) {
          problems.add('$path contains an open placeholder');
        }
      }
    }
  }
  return problems;
}

/// Checks whether the character counts stated in STORE-TEXTE.md are correct, e.g.
/// "(12 von 30 Zeichen)" or "(1158 of 4000 characters)".
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
            'STORE-TEXTE.md ($lang, ${m.group(1)}): states ${m.group(2)} '
            'characters, counted $actual',
          );
        }
      }
    }
  }
  return problems;
}

/// Reads all text files under [metadataDir] (relative path, with `/`).
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

/// Compares expected (from STORE-TEXTE.md) and actual (on disk).
List<String> checkInSync(
  Map<String, String> expected,
  Map<String, String> actual,
) {
  final List<String> problems = <String>[];
  for (final MapEntry<String, String> e in expected.entries) {
    final String? have = actual[e.key];
    if (have == null) {
      problems.add('fastlane/metadata/${e.key} is missing');
    } else if (have != e.value) {
      problems.add('fastlane/metadata/${e.key} differs from STORE-TEXTE.md');
    }
  }
  for (final String k in actual.keys) {
    if (!expected.containsKey(k)) {
      problems.add('fastlane/metadata/$k is unknown (not in STORE-TEXTE.md)');
    }
  }
  return problems;
}

/// Overall check for the repo under [root].
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
    stdout.writeln('${expected.length} files written to ${dir.path}.');
    return;
  }
  final List<String> problems = checkRepo(root);
  if (problems.isEmpty) {
    stdout.writeln('Store metadata OK.');
    return;
  }
  problems.forEach(stderr.writeln);
  exitCode = 1;
}
