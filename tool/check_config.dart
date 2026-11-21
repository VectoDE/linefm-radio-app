// Prueft die Konfigurationsdateien der App unter assets/config/ (Issue #91).
//
//   dart run tool/check_config.dart            alle Dateien in assets/config/
//   dart run tool/check_config.dart pfad.json  nur diese Datei(en)
//
// Jede Datei hat einen festen Namen und einen eigenen Pruefer. Heute gibt es
// nur stations.json (Senderliste). Weitere Teile, etwa Betreiberangaben fuer
// das Impressum (Issue #98), kommen als neue Datei im selben Ordner dazu und
// werden unten in [_checkers] eingetragen; Ladeweg, CI-Schritt und Anleitung
// bleiben gleich. Unbekannte Dateien im Ordner gelten als Fehler, damit kein
// Tippfehler im Dateinamen unbemerkt bleibt.
//
// Exit-Code 0 = alles in Ordnung, 1 = mindestens ein Fehler.

import 'dart:io';

import 'package:linefm_radio/domain/stations_config.dart';

typedef _Checker = List<String> Function(File file, List<String> notes);

final Map<String, _Checker> _checkers = <String, _Checker>{
  'stations.json': _checkStations,
};

void main(List<String> args) {
  final files = args.isEmpty
      ? (Directory('assets/config').listSync().whereType<File>().toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[for (final a in args) File(a)];
  var failed = false;
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final checker = _checkers[name] ?? _checkerForPath(name);
    final notes = <String>[];
    final errors = checker == null
        ? <String>[
            'Unbekannte Datei. Erlaubt sind: ${_checkers.keys.join(', ')}.',
          ]
        : (file.existsSync()
              ? checker(file, notes)
              : <String>['Datei nicht gefunden.']);
    for (final n in notes) {
      stdout.writeln('HINWEIS ${file.path}: $n');
    }
    if (errors.isEmpty) {
      stdout.writeln('OK      ${file.path}');
    } else {
      failed = true;
      for (final e in errors) {
        stderr.writeln('FEHLER  ${file.path}: $e');
      }
    }
  }
  if (failed) exitCode = 1;
}

/// Pruefer nach Dateinamen-Muster (Testdateien wie stations_6.json).
_Checker? _checkerForPath(String name) =>
    name.startsWith('stations') && name.endsWith('.json')
    ? _checkStations
    : null;

List<String> _checkStations(File file, List<String> notes) {
  final result = parseStationsConfigBytes(file.readAsBytesSync());
  notes.addAll(result.notes.map((n) => n.toString()));
  final errors = <String>[for (final e in result.errors) e.toString()];
  if (!result.ok && errors.isEmpty) {
    errors.add('Mindestens ein Sender muss angezeigt werden ("aktiv": true).');
  }
  // Mitgelieferte Logos muessen im Repository liegen.
  for (final e in result.entries) {
    final asset = e.logoAsset;
    if (asset != null && !File(asset).existsSync()) {
      errors.add(
        '${e.line == null ? '' : 'Zeile ${e.line}: '}Die Logo-Datei '
        '"$asset" gibt es nicht. Lege sie dort ab oder lass "logoDatei" weg.',
      );
    }
  }
  return errors;
}
