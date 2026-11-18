// Aktiviert oder deaktiviert die optionale Firebase-Anbindung.
//
//   dart run tool/enable_firebase.dart             aktivieren
//   dart run tool/enable_firebase.dart --disable   zurueck auf den Stub
//   dart run tool/enable_firebase.dart --merge-config
//       zusaetzlich FIREBASE_CONFIG_JSON (Umgebungsvariable, JSON-Objekt mit
//       FIREBASE_*-Schluesseln) in config/app.json einmischen (CI-Weg)
//
// Standard-Builds enthalten keinen Firebase-Code: das Paket steht nicht in
// pubspec.yaml. Nur dieses Skript fuegt es hinzu (Spec 2.3).
import 'dart:convert';
import 'dart:io';

const _hookPath = 'lib/services/telemetry/firebase_hook.dart';
const _hookTemplate = 'tool/templates/firebase_hook.dart.tpl';
const _stubTemplate = 'tool/templates/firebase_hook_stub.dart.tpl';
const _packagePath = 'packages/linefm_firebase';
const _configPath = 'config/app.json';

Future<void> main(List<String> args) async {
  final disable = args.contains('--disable');
  final mergeConfig = args.contains('--merge-config');

  if (!File('pubspec.yaml').existsSync()) {
    _fail('Bitte im Projektstamm ausfuehren (pubspec.yaml fehlt).');
  }

  if (disable) {
    await _flutter(['pub', 'remove', 'linefm_firebase']);
    File(_stubTemplate).copySync(_hookPath);
    stdout.writeln('Firebase deaktiviert, Stub wiederhergestellt.');
    return;
  }

  if (mergeConfig) _mergeConfigFromEnv();

  await _flutter(['pub', 'add', 'linefm_firebase', '--path', _packagePath]);
  File(_hookTemplate).copySync(_hookPath);
  stdout.writeln(
    'Firebase aktiviert. Fuer den Build FIREBASE_ENABLED=true und die '
    'FIREBASE_*-Werte in config/app.json setzen (siehe docs/telemetry.md).',
  );
}

void _mergeConfigFromEnv() {
  final raw = Platform.environment['FIREBASE_CONFIG_JSON'];
  if (raw == null || raw.trim().isEmpty) {
    _fail('FIREBASE_CONFIG_JSON ist nicht gesetzt.');
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    _fail('FIREBASE_CONFIG_JSON ist kein gueltiges JSON: ${e.message}');
  }
  if (decoded is! Map<String, Object?>) {
    _fail('FIREBASE_CONFIG_JSON muss ein JSON-Objekt sein.');
  }
  final file = File(_configPath);
  final current = file.existsSync()
      ? jsonDecode(file.readAsStringSync()) as Map<String, Object?>
      : <String, Object?>{};
  for (final entry in decoded.entries) {
    if (entry.key.startsWith('FIREBASE_')) current[entry.key] = entry.value;
  }
  current['FIREBASE_ENABLED'] = true;
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(current)}\n',
  );
  stdout.writeln('FIREBASE_* in $_configPath eingemischt.');
}

Future<void> _flutter(List<String> args) async {
  final result = await Process.run('flutter', args, runInShell: true);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    _fail('flutter ${args.join(' ')} fehlgeschlagen (${result.exitCode}).');
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
