// Enables or disables the optional Firebase integration.
//
//   dart run tool/enable_firebase.dart             enable
//   dart run tool/enable_firebase.dart --disable   back to the stub
//   dart run tool/enable_firebase.dart --merge-config
//       additionally merge FIREBASE_CONFIG_JSON (environment variable, JSON
//       object with FIREBASE_* keys) into config/app.json (CI route)
//
// Standard builds contain no Firebase code: the package is not listed in
// pubspec.yaml. Only this script adds it (spec 2.3).
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
    _fail('Please run from the project root (pubspec.yaml is missing).');
  }

  if (disable) {
    await _flutter(['pub', 'remove', 'linefm_firebase']);
    File(_stubTemplate).copySync(_hookPath);
    stdout.writeln('Firebase disabled, stub restored.');
    return;
  }

  if (mergeConfig) _mergeConfigFromEnv();

  await _flutter(['pub', 'add', 'linefm_firebase', '--path', _packagePath]);
  File(_hookTemplate).copySync(_hookPath);
  stdout.writeln(
    'Firebase enabled. For the build, set FIREBASE_ENABLED=true and the '
    'FIREBASE_* values in config/app.json (see docs/telemetry.md).',
  );
}

void _mergeConfigFromEnv() {
  final raw = Platform.environment['FIREBASE_CONFIG_JSON'];
  if (raw == null || raw.trim().isEmpty) {
    _fail('FIREBASE_CONFIG_JSON is not set.');
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    _fail('FIREBASE_CONFIG_JSON is not valid JSON: ${e.message}');
  }
  if (decoded is! Map<String, Object?>) {
    _fail('FIREBASE_CONFIG_JSON must be a JSON object.');
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
  stdout.writeln('FIREBASE_* merged into $_configPath.');
}

Future<void> _flutter(List<String> args) async {
  final result = await Process.run('flutter', args, runInShell: true);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    _fail('flutter ${args.join(' ')} failed (${result.exitCode}).');
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
