// Prueft tool/legal_store_check.py als echten Prozess (Exit-Code), mit einer
// Kopie von assets/legal in einem Temp-Verzeichnis. Ohne Python wird
// uebersprungen (die CI-Runner haben python3).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String? _python() {
  for (final String exe in <String>['python3', 'python']) {
    try {
      final ProcessResult r = Process.runSync(exe, <String>['--version']);
      if (r.exitCode == 0) return exe;
    } on ProcessException {
      // naechsten Namen versuchen
    }
  }
  return null;
}

void main() {
  final String? python = _python();
  final String script = File('tool/legal_store_check.py').absolute.path;
  final Map<String, Object?> registry =
      (jsonDecode(File('assets/legal/placeholders.json').readAsStringSync())
              as Map<String, Object?>)['placeholders']!
          as Map<String, Object?>;

  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('legalcheck');
    for (final String lang in <String>['de', 'en']) {
      Directory('${root.path}/assets/legal/$lang').createSync(recursive: true);
      for (final String kind in <String>['impressum', 'datenschutz']) {
        File('assets/legal/$lang/$kind.json')
            .copySync('${root.path}/assets/legal/$lang/$kind.json');
      }
    }
    File('assets/legal/placeholders.json')
        .copySync('${root.path}/assets/legal/placeholders.json');
  });
  tearDown(() => root.deleteSync(recursive: true));

  Map<String, String> allValues([String Function(String k)? v]) =>
      <String, String>{
        for (final String k in registry.keys) k: v?.call(k) ?? 'X',
      };

  ProcessResult run(Map<String, String> values, [String providers = '']) =>
      Process.runSync(
        python!,
        <String>[
          '-I',
          script,
          '--root',
          root.path,
          '--fill',
          if (providers.isNotEmpty) '--providers=$providers',
        ],
        environment: <String, String>{'LEGAL_VALUES_JSON': jsonEncode(values)},
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

  test('alle Werte gesetzt: Exit 0', () {
    final ProcessResult r = run(allValues());
    expect(r.exitCode, 0, reason: '${r.stderr}');
  }, skip: python == null ? 'kein Python' : false);

  test('leerer Pflichtwert: Exit 1', () {
    final ProcessResult r = run(
      allValues((String k) => k == 'BETREIBER_NAME' ? '' : 'X'),
    );
    expect(r.exitCode, 1);
    expect('${r.stderr}', contains('BETREIBER_NAME'));
  }, skip: python == null ? 'kein Python' : false);

  test('Wert nur aus Leerzeichen: Exit 1', () {
    final ProcessResult r = run(
      allValues((String k) => k == 'HOSTING_ANBIETER' ? '   ' : 'X'),
    );
    expect(r.exitCode, 1);
    expect('${r.stderr}', contains('HOSTING_ANBIETER'));
  }, skip: python == null ? 'kein Python' : false);

  test('optionale Anbieterangabe ohne Telemetrie offen: Exit 0', () {
    final Map<String, String> v = allValues()
      ..remove('UMAMI_BETREIBER')
      ..remove('TELEMETRIE_AUFBEWAHRUNG');
    expect(run(v).exitCode, 0);
  }, skip: python == null ? 'kein Python' : false);

  test('aktive Telemetrie macht Anbieterangaben zur Pflicht: Exit 1', () {
    final Map<String, String> v = allValues()
      ..remove('UMAMI_BETREIBER')
      ..remove('TELEMETRIE_AUFBEWAHRUNG');
    final ProcessResult r = run(v, 'umami');
    expect(r.exitCode, 1);
    expect('${r.stderr}', contains('UMAMI_BETREIBER'));
    expect('${r.stderr}', contains('TELEMETRIE_AUFBEWAHRUNG'));
  }, skip: python == null ? 'kein Python' : false);

  test('unregistrierter Platzhalter ist Pflicht: Exit 1', () {
    final File f = File('${root.path}/assets/legal/de/impressum.json');
    f.writeAsStringSync(
      f.readAsStringSync().replaceFirst('{{BETREIBER_NAME}}', '{{NEU_X}}'),
    );
    final ProcessResult r = run(allValues());
    expect(r.exitCode, 1);
    expect('${r.stderr}', contains('NEU_X'));
  }, skip: python == null ? 'kein Python' : false);

  test('Strict-Dateien mit Platzhalter: Exit 1', () {
    File('${root.path}/SECURITY.md').writeAsStringSync('{{SECURITY_KONTAKT}}');
    final ProcessResult r = run(allValues());
    expect(r.exitCode, 1);
    expect('${r.stderr}', contains('SECURITY.md'));
  }, skip: python == null ? 'kein Python' : false);
}
