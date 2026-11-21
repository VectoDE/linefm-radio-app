// Regressionstest zu genhtml "branchcov but no linecov": tool/coverage_report.sh
// darf keine Zweige (BRDA) fuer Zeilen ohne Zeilendatensatz (DA) ausgeben und
// muss LF/LH/BRF/BRH passend neu berechnen.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _lcov = '''
SF:lib/a.dart
FN:1,f
DA:1,1
DA:2,0
BRDA:2,0,0,1
BRDA:5,0,0,-
BRDA:5,0,1,1
BRF:3
BRH:2
LF:2
LH:1
end_of_record
SF:lib/l10n/gen/x.dart
DA:1,1
LF:1
LH:1
end_of_record
''';

Future<bool> _hasBash() async {
  try {
    final r = await Process.run('bash', <String>['--version']);
    return r.exitCode == 0;
  } on Object {
    return false;
  }
}

void main() {
  test(
    'Zweige ohne Zeilendatensatz werden verworfen, Summen stimmen',
    () async {
      if (!await _hasBash()) {
        markTestSkipped('bash nicht verfuegbar');
        return;
      }
      final dir = Directory.systemTemp.createTempSync('cov_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final input = File('${dir.path}/in.info')..writeAsStringSync(_lcov);
      final out = '${dir.path}/out';
      final r = await Process.run('bash', <String>[
        'tool/coverage_report.sh',
        input.path.replaceAll(r'\', '/'),
        '',
        out.replaceAll(r'\', '/'),
      ]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      final filtered = File('$out/lcov.filtered.info').readAsStringSync();
      expect(filtered, isNot(contains('BRDA:5,')));
      expect(filtered, contains('BRDA:2,0,0,1'));
      expect(filtered, contains('BRF:1'));
      expect(filtered, contains('BRH:1'));
      expect(filtered, contains('LF:2'));
      expect(filtered, isNot(contains('l10n/gen')));
    },
  );
}
