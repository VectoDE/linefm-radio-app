// Prueft den Konfigurationsordner config/ (Issue #91, Aufbau fuer #98).
//
//   dart run tool/check_config.dart              ganzen Ordner pruefen
//   dart run tool/check_config.dart datei.yaml   nur diese Datei(en)
//   dart run tool/check_config.dart --defines config/app.json
//       schreibt die Bauwerte (app + features: Standardwerte, ueberschrieben
//       von config/app.yaml und config/features.yaml, falls vorhanden) als
//       flaches JSON fuer `flutter build --dart-define-from-file=...`.
//
// Regeln:
// - Alle Dateien sind YAML mit Kommentaren. Jede Datei hat einen festen
//   Namen; unbekannte Dateien sind ein Fehler.
// - Ueber jedem Schluessel steht ein Kommentar (Bedeutung, Pflicht/optional,
//   Werte/Format, Standard, Beispiel). Fehlt er, ist das ein Fehler.
// - Jede *.example.yaml enthaelt ALLE Schluessel ihres Schemas, keine
//   weiteren, mit dem richtigen Typ und genau dem Standardwert.
// - Echte Dateien (ohne "example", per .gitignore nicht im Repo) werden
//   geprueft, wenn sie vorhanden sind.
// - config/stations.yaml ist die einzige echte Datei im Repo und wird streng
//   geprueft (lib/domain/stations_config.dart, dieselbe Regel wie in der App).
// - app.example.yaml muss jeden Wert enthalten, den der App-Code per
//   String/bool.fromEnvironment liest (ausser denen aus features).
//
// Neues Thema = neuer Eintrag in [_schemas]; Ladeweg und CI bleiben gleich.
// Exit-Code 0 = alles in Ordnung, 1 = mindestens ein Fehler.

import 'dart:convert';
import 'dart:io';

import 'package:linefm_radio/domain/stations_config.dart';
import 'package:yaml/yaml.dart';

/// Typ und Standardwert eines Schluessels.
sealed class _Type {
  const _Type();
  Object get standard;
}

class _Str extends _Type {
  const _Str([this.pattern, this.standard = '']);
  final String? pattern;
  @override
  final String standard;
}

class _Bool extends _Type {
  const _Bool();
  @override
  bool get standard => false;
}

class _OneOf extends _Type {
  const _OneOf(this.values);
  final List<String> values;
  @override
  String get standard => values.first;
}

const _str = _Str();
const _bool = _Bool();
const _https = _Str(r'^$|^https://\S+$');

const Map<String, Map<String, _Type>> _schemas = <String, Map<String, _Type>>{
  'app': <String, _Type>{
    'APP_ENV': _OneOf(<String>['dev', 'prod']),
    'APP_VERSION': _Str(r'^\d+\.\d+\.\d+([-+][0-9A-Za-z.-]+)?$', '1.0.0'),
    'WEB_BASE_URL': _Str(r'^https://\S*[^/\s]$', 'https://app.linefm.de'),
    'UMAMI_URL': _https,
    'UMAMI_WEBSITE_ID': _str,
    'SENTRY_DSN': _https,
    'SENTRY_ENVIRONMENT': _str,
    'FIREBASE_ENABLED': _bool,
    'FIREBASE_API_KEY': _str,
    'FIREBASE_PROJECT_ID': _str,
    'FIREBASE_MESSAGING_SENDER_ID': _str,
    'FIREBASE_APP_ID_ANDROID': _str,
    'FIREBASE_APP_ID_IOS': _str,
    'FIREBASE_APP_ID_MACOS': _str,
    'FIREBASE_APP_ID_WEB': _str,
    'WS_ENABLED': _bool,
    'GSC_VERIFICATION': _str,
    'GTM_ID': _Str(r'^$|^GTM-[A-Z0-9]+$'),
    'GA4_MEASUREMENT_ID': _Str(r'^$|^G-[A-Z0-9]+$'),
    'TRUST_GRIDINSOFT_URL': _https,
    'TRUST_TRUSTPILOT_URL': _https,
    'STATIONS_URL': _https,
  },
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
    'umamiUrl': _https,
    'umamiWebsiteId': _str,
    'sentryDsn': _https,
    'sentryEnvironment': _str,
    'firebaseEnabled': _bool,
  },
  'updater': <String, _Type>{
    'enabled': _bool,
    'channel': _OneOf(<String>['stable', 'beta']),
  },
};

void main(List<String> args) {
  if (args.length == 2 && args.first == '--defines') {
    exitCode = _writeDefines(File(args[1]));
    return;
  }
  final files = args.isEmpty
      ? (Directory('config')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml'))
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
  final text = file.readAsStringSync();
  if (name.startsWith('stations') &&
      (name.endsWith('.yaml') || name.endsWith('.json'))) {
    return <String>[
      if (name.endsWith('.yaml')) ..._missingComments(text),
      ..._checkStations(file, notes),
    ];
  }
  final match = RegExp(r'^([a-z]+)(\.example)?\.ya?ml$').firstMatch(name);
  final schema = match == null ? null : _schemas[match.group(1)];
  if (match == null || schema == null) {
    return <String>[
      'Unbekannte Datei. Erlaubt sind stations.yaml und '
          '${_schemas.keys.map((k) => '$k(.example).yaml').join(', ')}.',
    ];
  }
  final example = match.group(2) != null;
  return <String>[
    ..._missingComments(text),
    ..._checkSchema(text, schema, example: example),
    if (example && match.group(1) == 'app') ..._appKeysInCode(text),
  ];
}

/// Jeder Schluessel auf oberster Ebene braucht direkt darueber einen
/// Kommentar; mehrere Schluessel unter einem Kommentar (Gruppe) sind
/// erlaubt, eine Leerzeile dazwischen nicht. Die Felder der Sender erklaert
/// der Kommentarblock ueber `sender:`.
List<String> _missingComments(String text) {
  final errors = <String>[];
  final lines = const LineSplitter().convert(text);
  final key = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*:');
  for (var i = 0; i < lines.length; i++) {
    if (!key.hasMatch(lines[i])) continue;
    var j = i - 1;
    while (j >= 0 && key.hasMatch(lines[j])) {
      j--;
    }
    if (j < 0 || !lines[j].trimLeft().startsWith('#')) {
      errors.add(
        'Zeile ${i + 1}: Über "${lines[i].split(':').first}" fehlt der '
        'Kommentar (Bedeutung, Pflicht/optional, Werte, Standard, Beispiel).',
      );
    }
  }
  return errors;
}

Map<String, Object?>? _readYaml(String text, List<String> errors) {
  try {
    final data = loadYaml(text);
    if (data is YamlMap) {
      return <String, Object?>{
        for (final e in data.entries) '${e.key}': e.value,
      };
    }
    if (data == null) return <String, Object?>{};
    errors.add('Die Datei muss aus Zeilen "schluessel: wert" bestehen.');
  } on YamlException catch (e) {
    final span = e.span;
    final line = span == null ? '' : 'Zeile ${span.start.line + 1}: ';
    errors.add(
      '${line}Kein gültiges YAML (${e.message}). Häufig: Tab statt '
      'Leerzeichen oder "#" ohne Anführungszeichen.',
    );
  }
  return null;
}

List<String> _checkSchema(
  String text,
  Map<String, _Type> schema, {
  required bool example,
}) {
  final errors = <String>[];
  final data = _readYaml(text, errors);
  if (data == null) return errors;
  for (final key in schema.keys) {
    if (!data.containsKey(key)) errors.add('Schlüssel "$key" fehlt.');
  }
  for (final MapEntry(:key, :value) in data.entries) {
    final type = schema[key];
    if (type == null) {
      errors.add(
        'Schlüssel "$key" ist unbekannt. Erlaubt: ${schema.keys.join(', ')}.',
      );
      continue;
    }
    switch (type) {
      case _Bool():
        if (value is! bool) {
          errors.add(
            '"$key" muss true oder false sein (ohne Anführungszeichen).',
          );
        }
      case _OneOf(:final values):
        if (value is! String || !values.contains(value)) {
          errors.add(
            '"$key" muss einer dieser Werte sein: ${values.join(', ')}.',
          );
        }
      case _Str(:final pattern):
        if (value is! String) {
          errors.add(
            '"$key" muss Text sein (im Zweifel in Anführungszeichen).',
          );
        } else if (pattern != null && !RegExp(pattern).hasMatch(value)) {
          errors.add('"$key" hat ein ungültiges Format: "$value".');
        }
    }
    if (example && value != type.standard) {
      errors.add(
        '"$key" muss in der Beispieldatei den Standardwert haben '
        '(${jsonEncode(type.standard)}).',
      );
    }
  }
  return errors;
}

List<String> _appKeysInCode(String text) {
  final data = _readYaml(text, <String>[]) ?? const <String, Object?>{};
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
  final features = _schemas['features']!.keys.toSet();
  return <String>[
    for (final key in read.difference(features))
      if (!data.containsKey(key))
        'Schlüssel "$key" fehlt (liest der App-Code).',
  ];
}

List<String> _checkStations(File file, List<String> notes) {
  final result = parseStationsConfigBytes(file.readAsBytesSync());
  notes.addAll(result.notes.map((n) => n.toString()));
  final errors = <String>[for (final e in result.errors) e.toString()];
  if (!result.ok && errors.isEmpty) {
    errors.add('Mindestens ein Sender muss angezeigt werden (aktiv: true).');
  }
  for (final e in result.entries) {
    final asset = e.logoAsset;
    if (asset != null && !File(asset).existsSync()) {
      errors.add(
        '${e.line == null ? '' : 'Zeile ${e.line}: '}Die Logo-Datei '
        '"$asset" gibt es nicht. Lege sie dort ab oder lass logoDatei weg.',
      );
    }
  }
  return errors;
}

/// Bauwerte fuer --dart-define-from-file: Standardwerte der Schemas,
/// ueberschrieben von config/app.yaml und config/features.yaml (geprueft).
int _writeDefines(File out) {
  final values = <String, Object>{};
  for (final topic in <String>['app', 'features']) {
    final schema = _schemas[topic]!;
    for (final e in schema.entries) {
      values[e.key] = e.value.standard;
    }
    final real = File('config/$topic.yaml');
    if (!real.existsSync()) continue;
    final text = real.readAsStringSync();
    final errors = _checkSchema(text, schema, example: false);
    if (errors.isNotEmpty) {
      for (final e in errors) {
        stderr.writeln('FEHLER  ${real.path}: $e');
      }
      return 1;
    }
    for (final e in _readYaml(text, <String>[])!.entries) {
      final v = e.value;
      if (v != null) values[e.key] = v;
    }
    stdout.writeln('${real.path} übernommen.');
  }
  out.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(values)}\n',
  );
  stdout.writeln('${out.path} geschrieben.');
  return 0;
}
