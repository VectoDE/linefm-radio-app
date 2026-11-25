// Einheitlicher Aufgaben-Starter fuer Windows, Linux und macOS, ohne zusaetzliche
// Laufzeit-Abhaengigkeit (nur dart:).
//
// Aufruf im Repo-Wurzelverzeichnis:
//   dart tool/task.dart <aufgabe> [argumente]
//
// "dart tool/task.dart" statt "dart run tool/task.dart": Mit "run" baut Dart die
// Native-Asset-Hooks der Abhaengigkeiten (Rust, GTK) mit, das dauert und braucht
// auf Linux die Systempakete. Die Aufgaben hier brauchen das nicht.
//
// Aufgaben siehe [tasks] oder "dart tool/task.dart help". Beschreibung:
// docs/ENTWICKLUNG.md.
import 'dart:io';

/// Ein Befehl: Programm und Argumente.
typedef Command = List<String>;

/// Eine benannte Aufgabe, die aus einem oder mehreren Befehlen besteht.
class TaskDef {
  const TaskDef(this.description, this.build);

  final String description;

  /// Liefert die Befehle. [args] sind die Argumente hinter dem Aufgabennamen.
  final List<Command> Function(List<String> args) build;
}

/// Aufgaben. Die Reihenfolge entspricht dem, was die CI tut (ci.yml).
final Map<String, TaskDef> tasks = <String, TaskDef>{
  'pub-get': TaskDef(
    'Abhaengigkeiten holen (Lockdatei einhalten)',
    (_) => <Command>[
      <String>['flutter', 'pub', 'get', '--enforce-lockfile'],
    ],
  ),
  'format': TaskDef(
    'Dart-Code formatieren',
    (_) => <Command>[
      <String>['dart', 'format', '.'],
    ],
  ),
  'format-check': TaskDef(
    'Formatierung pruefen, ohne zu aendern (wie die CI)',
    (_) => <Command>[
      <String>['dart', 'format', '--output=none', '--set-exit-if-changed', '.'],
    ],
  ),
  'analyze': TaskDef(
    'Analyzer mit fatal-infos (wie die CI)',
    (_) => <Command>[
      <String>['flutter', 'analyze', '--fatal-infos'],
    ],
  ),
  'test': TaskDef(
    'Tests. Ohne Argument alle, sonst die genannten Dateien oder Ordner',
    (List<String> args) => <Command>[
      <String>['flutter', 'test', ...args],
    ],
  ),
  'gen-l10n': TaskDef(
    'Lokalisierung neu erzeugen (lib/l10n/gen)',
    (_) => <Command>[
      <String>['flutter', 'gen-l10n'],
    ],
  ),
  'store-metadata': TaskDef(
    'Store-Metadaten pruefen. Mit --write aus docs/STORE-TEXTE.md neu erzeugen',
    (List<String> args) => <Command>[
      <String>['dart', 'tool/store_metadata.dart', ...args],
    ],
  ),
  'web-build': TaskDef(
    'Web-Version bauen (Build, Ersatzschriften, Postbuild) nach build/web',
    (_) => <Command>[
      <String>[
        'flutter',
        'build',
        'web',
        '--release',
        '--wasm',
        '--no-web-resources-cdn',
        '--dart-define-from-file=config/app.json',
        '--base-href',
        '/',
      ],
      <String>[
        'dart',
        'tool/fetch_font_fallback.dart',
        'build/web',
        '--strict',
      ],
      <String>['dart', 'tool/web_postbuild.dart', 'build/web'],
    ],
  ),
  'check': TaskDef(
    'Alles, was vor einem Änderungsvorschlag laufen sollte: Format, Analyzer, Tests',
    (_) => <Command>[
      ...tasks['format-check']!.build(const <String>[]),
      ...tasks['analyze']!.build(const <String>[]),
      ...tasks['test']!.build(const <String>[]),
    ],
  ),
};

/// Haengt unter Windows die Endung an, die der Start ohne Shell braucht.
String resolveExecutable(String name, {required bool windows}) {
  if (!windows) return name;
  if (name == 'flutter' || name == 'dart') return '$name.bat';
  return name;
}

/// Fuer Tests: formatiert die Hilfe.
String helpText() {
  final StringBuffer b = StringBuffer(
    'Aufruf: dart tool/task.dart <aufgabe> [argumente]\n\nAufgaben:\n',
  );
  final int width = tasks.keys.fold<int>(
    0,
    (int m, String k) => k.length > m ? k.length : m,
  );
  for (final MapEntry<String, TaskDef> e in tasks.entries) {
    b.writeln('  ${e.key.padRight(width)}  ${e.value.description}');
  }
  return b.toString();
}

Future<int> run(List<String> args) async {
  if (args.isEmpty || args.first == 'help' || args.first == '--help') {
    stdout.write(helpText());
    return args.isEmpty ? 2 : 0;
  }
  final TaskDef? task = tasks[args.first];
  if (task == null) {
    stderr.writeln('Unbekannte Aufgabe "${args.first}".\n');
    stderr.write(helpText());
    return 2;
  }
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln(
      'Bitte im Repo-Wurzelverzeichnis starten (pubspec.yaml fehlt).',
    );
    return 2;
  }
  for (final Command c in task.build(args.sublist(1))) {
    final String exe = resolveExecutable(c.first, windows: Platform.isWindows);
    stdout.writeln('> ${c.join(' ')}');
    final Process p = await Process.start(
      exe,
      c.sublist(1),
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );
    final int code = await p.exitCode;
    if (code != 0) {
      stderr.writeln('Abbruch: "${c.join(' ')}" endete mit Code $code.');
      return code;
    }
  }
  return 0;
}

Future<void> main(List<String> args) async {
  exitCode = await run(args);
}
