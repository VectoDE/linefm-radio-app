// Prueft den Aufgaben-Starter tool/task.dart, ohne Befehle zu
// starten: Welche Befehle eine Aufgabe ausloest, Hilfe und Fehlercodes.
import 'package:flutter_test/flutter_test.dart';

import '../../tool/task.dart';

void main() {
  test('jede Aufgabe hat eine Beschreibung und mindestens einen Befehl', () {
    expect(tasks, isNotEmpty);
    for (final MapEntry<String, TaskDef> e in tasks.entries) {
      expect(e.value.description, isNotEmpty, reason: e.key);
      expect(e.value.build(const <String>[]), isNotEmpty, reason: e.key);
    }
  });

  test('die geforderten Aufgaben existieren', () {
    expect(
      tasks.keys,
      containsAll(<String>[
        'format',
        'analyze',
        'test',
        'gen-l10n',
        'web-build',
        'check',
      ]),
    );
  });

  test('check entspricht der CI: Format, Analyzer, Tests', () {
    final List<Command> cmds = tasks['check']!.build(const <String>[]);
    expect(cmds, <Command>[
      <String>['dart', 'format', '--output=none', '--set-exit-if-changed', '.'],
      <String>['flutter', 'analyze', '--fatal-infos'],
      <String>['flutter', 'test'],
    ]);
  });

  test('test reicht Argumente durch', () {
    expect(
      tasks['test']!.build(<String>['test/tool/task_test.dart']).single,
      <String>['flutter', 'test', 'test/tool/task_test.dart'],
    );
  });

  test(
    'web-build ruft Build, Ersatzschriften und Postbuild in dieser Reihenfolge',
    () {
      final List<Command> cmds = tasks['web-build']!.build(const <String>[]);
      expect(cmds.length, 3);
      expect(cmds[0], containsAll(<String>['build', 'web', '--wasm']));
      expect(cmds[1], contains('tool/fetch_font_fallback.dart'));
      expect(cmds[2], contains('tool/web_postbuild.dart'));
    },
  );

  test('Windows startet flutter und dart ueber die .bat-Dateien', () {
    expect(resolveExecutable('flutter', windows: true), 'flutter.bat');
    expect(resolveExecutable('dart', windows: true), 'dart.bat');
    expect(resolveExecutable('flutter', windows: false), 'flutter');
  });

  test('Hilfe nennt alle Aufgaben', () {
    final String help = helpText();
    for (final String name in tasks.keys) {
      expect(help, contains(name));
    }
  });

  test('unbekannte Aufgabe und fehlende Angabe liefern Code 2', () async {
    expect(await run(const <String>['gibtsnicht']), 2);
    expect(await run(const <String>[]), 2);
    expect(await run(const <String>['help']), 0);
  });
}
