// Prueft den Konfigurationsordner config/ (Issue #91, Aufbau fuer #98).
//
//   dart run tool/check_config.dart            ganzen Ordner config/ pruefen
//   dart run tool/check_config.dart pfad.json  nur diese Datei(en)
//
// Regeln:
// - Jede Datei hat einen festen Namen. Unbekannte Dateien sind ein Fehler.
// - Jede *.example.json enthaelt ALLE Schluessel ihres Schemas, keine
//   weiteren, mit dem richtigen Typ und ohne echte Werte.
// - Echte Dateien (ohne "example", per .gitignore nicht im Repo) werden
//   geprueft, wenn sie vorhanden sind.
// - config/stations.json (Senderliste) ist die einzige echte Datei im Repo
//   und wird streng geprueft (lib/domain/stations_config.dart).
// - app.example.json muss jeden Wert enthalten, den
//   lib/core/config/app_config.dart per String/bool.fromEnvironment liest
//   (ausser denen aus features.json); weitere Schluessel nutzen die
//   Bau-Werkzeuge (z. B. WEB_BASE_URL).
//
// Neuer Teil = neuer Eintrag in [_schemas]; Ladeweg und CI bleiben gleich.
// Exit-Code 0 = alles in Ordnung, 1 = mindestens ein Fehler.

import 'dart:convert';
import 'dart:io';

import 'package:linefm_radio/domain/stations_config.dart';

/// Typ eines Schluessels: Text, true/false oder eine feste Auswahl.
sealed class _Type {
  const _Type();
}

class _Str extends _Type {
  const _Str([this.pattern]);
  final String? pattern;
}

class _Bool extends _Type {
  const _Bool();
}

class _OneOf extends _Type {
  const _OneOf(this.values);
  final List<String> values;
}

const _str = _Str();
const _bool = _Bool();

/// Schemas der Dateien (Name ohne Endung). `hinweis` ist ueberall erlaubt.
const Map<String, Map<String, _Type>> _schemas = <String, Map<String, _Type>>{
  'features': <String, _Type>{'showListenerCount': _bool},
  'operator': <String, _Type>{
    'name': _str,
    'rechtsform': _str,
    'vertretenDurch': _str,
    'strasse': _str,
    'plz': _Str(r'^$|^[0-9A-Za-z -]{3,10}$'),
    'ort': _str,
    'land': _str,
    'email': _Str(r'^$|^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    'telefon': _Str(r'^$|^\+?[0-9 ()/-]{5,30}$'),
    'ustId': _str,
    'verantwortlichInhalt': _str,
  },
  'telemetry': <String, _Type>{
    'umamiUrl': _Str(r'^$|^https://'),
    'umamiWebsiteId': _str,
    'sentryDsn': _Str(r'^$|^https://'),
    'sentryEnvironment': _str,
    'firebaseEnabled': _bool,
  },
  'updater': <String, _Type>{
    'enabled': _bool,
    'channel': _OneOf(<String>['stable', 'beta']),
  },
};

/// Werte aus features.json (zweite --dart-define-from-file-Datei).
const Set<String> _featureDefines = <String>{'showListenerCount'};

void main(List<String> args) {
  final files = args.isEmpty
      ? (Directory('config')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[for (final a in args) File(a)];
  var failed = false;
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final notes = <String>[];
    final errors = file.existsSync()
        ? _check(file, name, notes)
        : <String>['Datei nicht gefunden.'];
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

List<String> _check(File file, String name, List<String> notes) {
  if (name.startsWith('stations') && name.endsWith('.json')) {
    return _checkStations(file, notes);
  }
  if (name == 'app.example.json' || name == 'app.json') {
    return _checkApp(file, example: name.contains('example'));
  }
  final match = RegExp(r'^([a-z]+)(\.example)?\.json$').firstMatch(name);
  final schema = match == null ? null : _schemas[match.group(1)];
  if (schema == null) {
    return <String>[
      'Unbekannte Datei. Erlaubt sind stations.json, app(.example).json und '
          '${_schemas.keys.map((k) => '$k(.example).json').join(', ')}.',
    ];
  }
  return _checkSchema(file, schema, example: match!.group(2) != null);
}

Map<String, Object?>? _readObject(File file, List<String> errors) {
  try {
    final data = jsonDecode(file.readAsStringSync());
    if (data is Map<String, Object?>) return data;
    errors.add('Die Datei muss ein JSON-Objekt { ... } sein.');
  } on FormatException catch (e) {
    errors.add('Kein gueltiges JSON: ${e.message}');
  }
  return null;
}

List<String> _checkSchema(
  File file,
  Map<String, _Type> schema, {
  required bool example,
}) {
  final errors = <String>[];
  final data = _readObject(file, errors);
  if (data == null) return errors;
  for (final key in schema.keys) {
    if (!data.containsKey(key)) errors.add('Schluessel "$key" fehlt.');
  }
  for (final MapEntry(:key, :value) in data.entries) {
    if (key == 'hinweis') continue;
    final type = schema[key];
    if (type == null) {
      errors.add(
        'Schluessel "$key" ist unbekannt. Erlaubt: ${schema.keys.join(', ')}.',
      );
      continue;
    }
    switch (type) {
      case _Bool():
        if (value is! bool) {
          errors.add(
            '"$key" muss true oder false sein (ohne Anfuehrungszeichen).',
          );
        } else if (example && value) {
          errors.add('"$key" muss in der Beispieldatei false sein.');
        }
      case _OneOf(:final values):
        if (value is! String || !values.contains(value)) {
          errors.add(
            '"$key" muss einer dieser Werte sein: ${values.join(', ')}.',
          );
        }
      case _Str(:final pattern):
        if (value is! String) {
          errors.add('"$key" muss Text in Anfuehrungszeichen sein.');
        } else if (example && value.isNotEmpty) {
          errors.add('"$key" muss in der Beispieldatei leer sein ("").');
        } else if (pattern != null && !RegExp(pattern).hasMatch(value)) {
          errors.add('"$key" hat ein ungueltiges Format: "$value".');
        }
    }
  }
  return errors;
}

List<String> _checkApp(File file, {required bool example}) {
  final errors = <String>[];
  final data = _readObject(file, errors);
  if (data == null) return errors;
  for (final MapEntry(:key, :value) in data.entries) {
    if (value is! String && value is! bool) {
      errors.add('"$key" muss Text oder true/false sein.');
    }
  }
  if (example) {
    // Alle Werte, die App und eigene Pakete per fromEnvironment lesen.
    final source = <Directory>[Directory('lib'), Directory('packages')]
        .where((d) => d.existsSync())
        .expand((d) => d.listSync(recursive: true))
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .join();
    final read = RegExp(r"(?:String|bool)\.fromEnvironment\('([A-Za-z0-9_]+)'")
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toSet();
    for (final key in read.difference(_featureDefines)) {
      if (!data.containsKey(key)) {
        errors.add('Schluessel "$key" fehlt (liest der App-Code).');
      }
    }
  }
  return errors;
}

List<String> _checkStations(File file, List<String> notes) {
  final result = parseStationsConfigBytes(file.readAsBytesSync());
  notes.addAll(result.notes.map((n) => n.toString()));
  final errors = <String>[for (final e in result.errors) e.toString()];
  if (!result.ok && errors.isEmpty) {
    errors.add('Mindestens ein Sender muss angezeigt werden ("aktiv": true).');
  }
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
