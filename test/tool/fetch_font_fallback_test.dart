import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/fetch_font_fallback.dart';

void main() {
  group('parseFallbackFontData', () {
    test('liest Name und Pfad, ohne Dubletten', () {
      const src = '''
List<NotoFont> getFallbackFontList() => <NotoFont>[
  NotoFont(
    'Noto Color Emoji 0',
    'notocoloremoji/v39/abc.0.woff2',
    index: 0,
  ),
  NotoFont('Noto Sans', 'notosans/v42/xyz.woff2', index: 1),
  NotoFont(
    'Noto Sans SC',
    'notosanssc/v40/full.woff2',
    index: 2,
    slices: const <String>{'Noto Sans SC 0'},
  ),
  NotoFont('Noto Sans 2', 'notosans/v42/xyz.woff2', index: 3),
];
''';
      final fonts = parseFallbackFontData(src);
      expect(fonts.map((f) => f.path), <String>[
        'notocoloremoji/v39/abc.0.woff2',
        'notosans/v42/xyz.woff2',
        'notosanssc/v40/full.woff2',
      ]);
      expect(fonts.first.name, 'Noto Color Emoji 0');
      expect(fonts.map((f) => f.group), <String>['core', 'core', 'cjk']);
    });

    test('Roboto-Pfad aus der Engine', () {
      const src =
          "String _robotoUrl =\n    '\${configuration.fontFallbackBaseUrl}roboto/v32/K.woff2';";
      expect(parseRobotoPath(src), 'roboto/v32/K.woff2');
    });
  });

  test('isSafeRelativePath', () {
    expect(isSafeRelativePath('notosans/v42/x.woff2'), isTrue);
    expect(isSafeRelativePath('../x.woff2'), isFalse);
    expect(isSafeRelativePath('/etc/x'), isFalse);
    expect(isSafeRelativePath(r'a\b'), isFalse);
    expect(isSafeRelativePath('c:/x'), isFalse);
    expect(isSafeRelativePath('a//b'), isFalse);
  });

  test('Sperrdatei: Runde ueber encodeLock und parseLock', () {
    final text = encodeLock(
      engineRevision: 'rev',
      source: defaultSource,
      fonts: <FallbackFont>[
        FallbackFont('B', 'notosanskr/v1/b.woff2', sha256: 'b' * 64, bytes: 5),
        FallbackFont('A', 'notosans/v1/a.woff2', sha256: 'a' * 64, bytes: 3),
      ],
    );
    final json = jsonDecode(text) as Map<String, dynamic>;
    expect(json['totals'], <String, int>{'core': 3, 'cjk': 5, 'files': 2});
    final lock = parseLock(text);
    expect(lock.engineRevision, 'rev');
    expect(lock.fonts.map((f) => f.path), <String>[
      'notosans/v1/a.woff2',
      'notosanskr/v1/b.woff2',
    ]);
  });

  test('Sperrdatei ohne Pruefsumme oder mit Pfadausbruch wird abgelehnt', () {
    String lock(String path, String? sha) => jsonEncode(<String, Object?>{
      'fonts': <Object?>[
        <String, Object?>{'name': 'x', 'path': path, 'sha256': sha},
      ],
    });
    expect(
      () => parseLock(lock('a/b.woff2', null)),
      throwsA(isA<FontFallbackException>()),
    );
    expect(
      () => parseLock(lock('../b.woff2', 'a' * 64)),
      throwsA(isA<FontFallbackException>()),
    );
  });

  test('Lizenztext ohne fremden Urheberkopf', () {
    final out = renderLicense(File('assets/fonts/OFL.txt').readAsStringSync());
    expect(out, isNot(contains('Poppins')));
    expect(out, contains('Noto Project Authors'));
    expect(out, contains('SIL Open Font License, Version 1.1'));
  });

  test('diffPaths', () {
    final d = diffPaths(<String>['a', 'b'], <String>['b', 'c']);
    expect(d.onlySdk, <String>['a']);
    expect(d.onlyLock, <String>['c']);
  });

  test('Sperrdatei im Repo ist vollstaendig und passt zum Bootstrap', () {
    final lock = parseLock(
      File('tool/font_fallback.lock.json').readAsStringSync(),
    );
    final paths = lock.fonts.map((f) => f.path).toSet();
    expect(paths.length, lock.fonts.length);
    expect(paths.where((p) => p.startsWith('roboto/')), hasLength(1));
    expect(paths.where((p) => p.startsWith('notocoloremoji/')), isNotEmpty);
    expect(paths.where((p) => p.startsWith('notosans/')), isNotEmpty);
    expect(lock.fonts.where((f) => f.group == 'cjk'), isNotEmpty);
    expect(
      File('web/flutter_bootstrap.js').readAsStringSync(),
      contains("fontFallbackBaseUrl: 'assets/fonts/fallback/'"),
    );
  });

  test(
    'fehlende OFL.txt bricht vor jedem Download mit Exit 1 ab (R3-P07)',
    () async {
      final tmp = Directory.systemTemp.createTempSync('fff');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final code = await runCli(<String>[
        tmp.path,
        '--license',
        '${tmp.path}/fehlt/OFL.txt',
        '--source',
        'http://127.0.0.1:9/',
      ]);
      expect(code, 1);
      expect(Directory('${tmp.path}/$fallbackSubdir').existsSync(), isFalse);
    },
  );
}
