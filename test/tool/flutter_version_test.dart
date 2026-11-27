// Eine Flutter-Version fuer alle Stellen. Quelle der Wahrheit ist
// .fvmrc. Dieser Test findet jede Abweichung: CI (setup-flutter), Dev-Container,
// pubspec.yaml und die Entwicklungsdoku. Ein Flutter-Update aendert alle Stellen
// zusammen, sonst schlaegt der Test fehl.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) =>
    File(path).readAsStringSync().replaceAll('\r\n', '\n');

String _first(String text, RegExp re, String what) {
  final Match? m = re.firstMatch(text);
  if (m == null) fail('$what nicht gefunden');
  return m.group(1)!;
}

void main() {
  final String pinned =
      (jsonDecode(_read('.fvmrc')) as Map<String, Object?>)['flutter']!
          as String;

  test('.fvmrc nennt eine exakte Version', () {
    expect(pinned, matches(RegExp(r'^\d+\.\d+\.\d+$')));
  });

  test('CI (setup-flutter) nutzt dieselbe Version', () {
    final String action = _read('.github/actions/setup-flutter/action.yml');
    final String v = _first(
      action,
      RegExp(r'flutter-version:\s*\n(?:.*\n)*?\s*default:\s*"([^"]+)"'),
      'Standard von flutter-version',
    );
    expect(v, pinned);
  });

  test('kein Workflow ueberschreibt die Version', () {
    for (final FileSystemEntity f in Directory(
      '.github/workflows',
    ).listSync()) {
      if (f is! File || !f.path.endsWith('.yml')) continue;
      final String text = f.readAsStringSync();
      for (final Match m in RegExp(
        r'^\s*flutter-version:\s*"?([^"\s]+)"?',
        multiLine: true,
      ).allMatches(text)) {
        expect(
          m.group(1),
          pinned,
          reason: '${f.path} setzt eine abweichende flutter-version',
        );
      }
    }
  });

  test('Dev-Container nutzt dieselbe Version und ein gepinntes Image', () {
    final String docker = _read('.devcontainer/Dockerfile');
    expect(
      _first(
        docker,
        RegExp(r'^ARG FLUTTER_VERSION=(\S+)', multiLine: true),
        'ARG FLUTTER_VERSION',
      ),
      pinned,
    );
    expect(
      _first(
        docker,
        RegExp(r'^ARG FLUTTER_SHA256=(\S+)', multiLine: true),
        'ARG FLUTTER_SHA256',
      ),
      matches(RegExp(r'^[0-9a-f]{64}$')),
    );
    expect(
      docker,
      matches(RegExp(r'^FROM \S+@sha256:[0-9a-f]{64}', multiLine: true)),
      reason: 'Das Basisimage muss per Digest gepinnt sein',
    );
    final Map<String, Object?> json = jsonDecode(
      _read('.devcontainer/devcontainer.json'),
    ) as Map<String, Object?>;
    expect(json['name'], contains(pinned));
  });

  test('pubspec.yaml verlangt mindestens diese Version', () {
    expect(
      _first(
        _read('pubspec.yaml'),
        RegExp(r'^\s*flutter:\s*">=([\d.]+)"', multiLine: true),
        'environment.flutter',
      ),
      pinned,
    );
  });

  test('ENTWICKLUNG.md nennt dieselbe Version', () {
    expect(
      _first(
        _read('docs/ENTWICKLUNG.md'),
        RegExp(r'^\| Flutter \| ([\d.]+)', multiLine: true),
        'Flutter-Zeile in der Voraussetzungstabelle',
      ),
      pinned,
    );
  });

  test('Snap part builds with the pinned Flutter and config/app.json', () {
    final String snap = _read('packaging/snap/snapcraft.yaml');
    expect(
      snap,
      isNot(matches(RegExp(r'^\s*plugin:\s*flutter', multiLine: true))),
      reason: 'plugin: flutter ignores the pin and config/app.json',
    );
    expect(snap, contains('.fvmrc'));
    expect(snap, contains('--dart-define-from-file=config/app.json'));
    expect(snap, contains('flutter pub get --enforce-lockfile'));
  });
}
