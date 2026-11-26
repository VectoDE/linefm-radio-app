// Checks the configuration folder config/ (structure also for the operator details).
//
//   dart run tool/check_config.dart              check the whole folder
//   dart run tool/check_config.dart file.yaml    only this file(s)
//   dart run tool/check_config.dart --defines config/app.json
//       writes the build values (app + features: default values, overridden
//       by config/app.yaml and config/features.yaml, if present) as
//       flat JSON for `flutter build --dart-define-from-file=...`.
//
// Rules:
// - All files are YAML with comments. Each file has a fixed
//   name; unknown files are an error.
// - Above every key there is a comment (meaning, required/optional,
//   values/format, default, example). If it is missing, that is an error.
// - Every *.example.yaml contains ALL keys of its schema, no
//   others, with the right type and exactly the default value.
// - Real files (without "example", not in the repo per .gitignore) are
//   checked if they exist.
// - config/stations.yaml is the only real file in the repo and is checked
//   strictly (lib/domain/stations_config.dart, same rule as in the app).
// - app.example.yaml must contain every value that the app code reads via
//   String/bool.fromEnvironment (except those from features and the values set
//   by the build: APP_VERSION, APP_COMMIT, LINEFM_PERF_MARKS).
//
// New topic = new entry in [_schemas]; loading path and CI stay the same.
// Exit code 0 = all good, 1 = at least one error.

import 'dart:convert';
import 'dart:io';

import 'package:linefm_radio/domain/stations_config.dart';
import 'package:yaml/yaml.dart';

/// Type and default value of a key.
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
        : <String>['File not found.'];
    for (final n in notes) {
      stdout.writeln('NOTE    ${file.path}: $n');
    }
    if (errors.isEmpty) {
      stdout.writeln('OK      ${file.path}');
    } else {
      failed = true;
      for (final e in errors) {
        stderr.writeln('ERROR   ${file.path}: $e');
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
      'Unknown file. Allowed are stations.yaml and '
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

/// Every top-level key needs a comment directly above it; several keys
/// under one comment (group) are allowed, a blank line in between is not.
/// The station fields are explained by the comment block above `sender:`.
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
        'Line ${i + 1}: The comment above "${lines[i].split(':').first}" is '
        'missing (meaning, required/optional, values, default, example).',
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
    errors.add('The file must consist of lines of the form "key: value".');
  } on YamlException catch (e) {
    final span = e.span;
    final line = span == null ? '' : 'Line ${span.start.line + 1}: ';
    errors.add(
      '${line}Not valid YAML (${e.message}). Common causes: tab instead of '
      'spaces or "#" without quotes.',
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
    if (!data.containsKey(key)) errors.add('Key "$key" is missing.');
  }
  for (final MapEntry(:key, :value) in data.entries) {
    final type = schema[key];
    if (type == null) {
      errors.add('Key "$key" is unknown. Allowed: ${schema.keys.join(', ')}.');
      continue;
    }
    switch (type) {
      case _Bool():
        if (value is! bool) {
          errors.add('"$key" must be true or false (without quotes).');
        }
      case _OneOf(:final values):
        if (value is! String || !values.contains(value)) {
          errors.add(
            '"$key" must be one of these values: ${values.join(', ')}.',
          );
        }
      case _Str(:final pattern):
        if (value is! String) {
          errors.add('"$key" must be text (in doubt, in quotes).');
        } else if (pattern != null && !RegExp(pattern).hasMatch(value)) {
          errors.add('"$key" has an invalid format: "$value".');
        }
    }
    if (example && value != type.standard) {
      errors.add(
        '"$key" must have the default value in the example file '
        '(${jsonEncode(type.standard)}).',
      );
    }
  }
  return errors;
}

// Set by the build or release workflow, never by the operator.
const Set<String> _injectedKeys = <String>{
  'APP_VERSION',
  'APP_COMMIT',
  'LINEFM_PERF_MARKS',
};

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
    for (final key in read.difference(features).difference(_injectedKeys))
      if (!data.containsKey(key))
        'Key "$key" is missing (read by the app code).',
  ];
}

List<String> _checkStations(File file, List<String> notes) {
  final result = parseStationsConfigBytes(file.readAsBytesSync());
  notes.addAll(result.notes.map((n) => n.toString()));
  final errors = <String>[for (final e in result.errors) e.toString()];
  if (!result.ok && errors.isEmpty) {
    errors.add('At least one station must be shown (aktiv: true).');
  }
  for (final e in result.entries) {
    final asset = e.logoAsset;
    if (asset != null && !File(asset).existsSync()) {
      errors.add(
        '${e.line == null ? '' : 'Line ${e.line}: '}The logo file '
        '"$asset" does not exist. Put it there or omit logoDatei.',
      );
    }
  }
  return errors;
}

/// Build values for --dart-define-from-file: default values of the schemas,
/// overridden by config/app.yaml and config/features.yaml (validated).
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
        stderr.writeln('ERROR   ${real.path}: $e');
      }
      return 1;
    }
    for (final e in _readYaml(text, <String>[])!.entries) {
      final v = e.value;
      if (v != null) values[e.key] = v;
    }
    stdout.writeln('${real.path} applied.');
  }
  out.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(values)}\n',
  );
  stdout.writeln('${out.path} written.');
  return 0;
}
