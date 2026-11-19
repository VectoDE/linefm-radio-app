// Gegenpruefung der Einrichtungsliste (Issue #64): Jeder Platzhalter, den der
// Betreiber fuellen muss, und jedes Secret bzw. jede Variable, die ein Workflow
// liest, steht in docs/EINRICHTUNG.md. Faellt etwas Neues dazu, schlaegt dieser
// Test fehl, bis die Liste nachgezogen ist.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ordner und Dateien, in denen Betreiber-Platzhalter `{{NAME}}` stehen koennen.
const List<String> placeholderRoots = <String>[
  'assets',
  'web',
  'packaging',
  'deploy',
  'SECURITY.md',
  'CODE_OF_CONDUCT.md',
  'CONTRIBUTING.md',
  'SUPPORT.md',
  'README.md',
  'docs/BARRIEREFREIHEIT.md',
];

const Set<String> _textExtensions = <String>{
  'md',
  'json',
  'txt',
  'html',
  'xml',
  'yml',
  'yaml',
  'conf',
  'template',
  'plist',
  'webmanifest',
  'js',
  'toml',
  'desktop',
  'metainfo',
  'htaccess',
};

final RegExp placeholderPattern = RegExp(r'\{\{\s*([A-Z][A-Z0-9_]*)\s*\}\}');
final RegExp _secretOrVar = RegExp(r'\b(?:secrets|vars)\.([A-Z][A-Z0-9_]+)');

/// Von GitHub selbst bereitgestellt, nichts einzurichten.
const Set<String> builtInSecrets = <String>{'GITHUB_TOKEN'};

bool _isText(String path) {
  final name = path.replaceAll('\\', '/').split('/').last;
  if (name == '_headers' || name == '_redirects' || name == '.htaccess') {
    return true;
  }
  final dot = name.lastIndexOf('.');
  return dot >= 0 && _textExtensions.contains(name.substring(dot + 1));
}

Iterable<File> _files(String root) sync* {
  final type = FileSystemEntity.typeSync(root);
  if (type == FileSystemEntityType.file) {
    yield File(root);
  } else if (type == FileSystemEntityType.directory) {
    for (final e in Directory(root).listSync(recursive: true)) {
      if (e is File && _isText(e.path)) yield e;
    }
  }
}

/// Alle Platzhalter-Namen mit der ersten Fundstelle.
Map<String, String> collectPlaceholders() {
  final found = <String, String>{};
  for (final root in placeholderRoots) {
    for (final f in _files(root)) {
      final String text;
      try {
        text = f.readAsStringSync();
      } on FileSystemException {
        continue; // keine UTF-8-Datei
      }
      for (final m in placeholderPattern.allMatches(text)) {
        found.putIfAbsent(m.group(1)!, () => f.path.replaceAll('\\', '/'));
      }
    }
  }
  final registry =
      (jsonDecode(File('assets/legal/placeholders.json').readAsStringSync())
              as Map<String, dynamic>)['placeholders']
          as Map<String, dynamic>;
  for (final k in registry.keys) {
    found.putIfAbsent(k, () => 'assets/legal/placeholders.json');
  }
  return found;
}

/// Alle `secrets.*`/`vars.*` aus `${{ ... }}`-Ausdruecken der Workflows und
/// lokalen Actions, mit der ersten Fundstelle.
Map<String, String> collectSecretsAndVars() {
  final found = <String, String>{};
  for (final f in _files('.github')) {
    final lines = f.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.contains(r'${{')) continue;
      for (final m in _secretOrVar.allMatches(line)) {
        final name = m.group(1)!;
        if (builtInSecrets.contains(name)) continue;
        found.putIfAbsent(
          name,
          () => '${f.path.replaceAll('\\', '/')}:${i + 1}',
        );
      }
    }
  }
  return found;
}

/// Ist [name] in [doc] genannt (`NAME` in Backticks oder als `{{NAME}}`)?
bool mentioned(String doc, String name) =>
    doc.contains('`$name`') || doc.contains('{{$name}}');

void main() {
  final doc = File('docs/EINRICHTUNG.md').readAsStringSync();

  test('Sammler finden etwas (Schutz gegen leere Suche)', () {
    expect(collectPlaceholders(), contains('BETREIBER_NAME'));
    expect(collectSecretsAndVars(), contains('PLAY_SERVICE_ACCOUNT_JSON'));
    expect(collectSecretsAndVars(), contains('GTM_ID'));
    expect(collectSecretsAndVars(), contains('GPG_PRIVATE_KEY'));
  });

  test('jeder Platzhalter steht in docs/EINRICHTUNG.md', () {
    final missing = <String>[
      for (final e in collectPlaceholders().entries)
        if (!mentioned(doc, e.key)) '{{${e.key}}} (${e.value})',
    ]..sort();
    expect(missing, isEmpty, reason: 'in EINRICHTUNG.md nachtragen');
  });

  test('jedes Secret und jede Variable steht in docs/EINRICHTUNG.md', () {
    final missing = <String>[
      for (final e in collectSecretsAndVars().entries)
        if (!mentioned(doc, e.key)) '${e.key} (${e.value})',
    ]..sort();
    expect(missing, isEmpty, reason: 'in EINRICHTUNG.md nachtragen');
  });

  test('kein offener Sicherheitskontakt-Platzhalter mehr', () {
    for (final path in <String>[
      'SECURITY.md',
      'CODE_OF_CONDUCT.md',
      'web/.well-known/security.txt',
    ]) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains('{{SECURITY_KONTAKT}}')),
        reason: path,
      );
    }
    expect(
      File('web/.well-known/security.txt').readAsStringSync(),
      contains(
        'Contact: https://github.com/VectoDE/linefm-radio-app/security/advisories/new',
      ),
    );
  });

  test('Erkennung: Muster und Hilfsfunktionen', () {
    expect(
      placeholderPattern.allMatches('a {{X_1}} b {{ Y }}').map((m) => m[1]),
      <String>['X_1', 'Y'],
    );
    expect(mentioned('Trag `FOO` ein', 'FOO'), isTrue);
    expect(mentioned('{{BAR}} fuellen', 'BAR'), isTrue);
    expect(mentioned('FOOBAR', 'FOO'), isFalse);
  });
}
