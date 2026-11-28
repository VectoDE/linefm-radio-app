import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/web_postbuild.dart';
import 'web_postbuild_helpers.dart';

void main() {
  group('runPostbuild', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('postbuild_test'));
    tearDown(() => tmp.deleteSync(recursive: true));

    void write(String path, String content) => File('${tmp.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);

    test('real hosting templates get hashes and one stable nonce', () {
      write(
        'web/flutter_bootstrap.js',
        bootstrap().replaceFirst(
          'var config = {};',
          "var config = {nonce: '$cspStyleNoncePlaceholder'};",
        ),
      );
      write('web/main.dart.js', 'js');
      write('web/canvaskit/canvaskit.wasm', 'ck');
      write('web/sw.js', "const BUILD_ID = '__BUILD_ID__';");
      write('web/index.html', '<style>a{}</style>');
      const templates = <String>[
        'cloudflare/_headers',
        'plesk/.htaccess',
        'plesk/nginx-additional.conf',
        'nginx/snippets/linefm-headers.conf',
      ];
      for (final t in templates) {
        write('deploy/$t', File('deploy/$t').readAsStringSync());
      }
      PostbuildOptions opts() => PostbuildOptions(
        webDir: Directory('${tmp.path}/web'),
        deployDir: '${tmp.path}/deploy',
        hostingOut: '${tmp.path}/hosting',
      );

      String? nonceAfterRun() {
        runPostbuild(opts());
        final nonce = existingStyleNonce(
          File('${tmp.path}/web/flutter_bootstrap.js').readAsStringSync(),
        );
        expect(nonce, isNotNull);
        for (final t in templates) {
          final text = File('${tmp.path}/hosting/$t').readAsStringSync();
          final styleSrc = RegExp(r'\bstyle-src\s[^;\x22\n]*')
              .firstMatch(text)!
              .group(0)!;
          expect(styleSrc, contains("'nonce-$nonce'"), reason: t);
          expect(styleSrc, contains(cspSha256('a{}')), reason: t);
          expect(styleSrc, isNot(contains('unsafe-inline')), reason: t);
        }
        final headers = File('${tmp.path}/web/_headers').readAsStringSync();
        expect(headers, contains("'nonce-$nonce'"));
        return nonce;
      }

      final first = nonceAfterRun();
      expect(nonceAfterRun(), first);
    });

    test('Ende-zu-Ende auf einer Mini-Ausgabe', () {
      write('web/flutter_bootstrap.js', bootstrap());
      write('web/main.dart.js', 'js');
      write('web/main.dart.wasm', 'wasm');
      write('web/main.dart.mjs', 'mjs');
      write('web/canvaskit/canvaskit.wasm', 'ck');
      write('web/canvaskit/chromium/canvaskit.wasm', 'ck2');
      write('web/sw.js', "const BUILD_ID = '__BUILD_ID__';");
      write(
        'web/index.html',
        '<meta name="google-site-verification" content="__GSC_VERIFICATION__">',
      );
      write('deploy/cloudflare/_headers', 'x https://a $cspPlaceholder;');
      write('deploy/cloudflare/_redirects', '/* /index.html 200');
      write('deploy/plesk/.htaccess', 'h $cspPlaceholder');
      write('deploy/nginx/snippets/linefm-headers.conf', 'n $cspPlaceholder');
      write('netlify.toml', 'csp = "a $cspPlaceholder"');
      write('vercel.json', '{"value": "b $cspScriptPlaceholder"}');

      final written = runPostbuild(
        PostbuildOptions(
          webDir: Directory('${tmp.path}/web'),
          deployDir: '${tmp.path}/deploy',
          hostingOut: '${tmp.path}/hosting',
          cspConnectExtra: 'https://t.example',
        ),
      );

      final names = Directory('${tmp.path}/web')
          .listSync()
          .map((e) => e.path.split(RegExp(r'[\\/]')).last)
          .toList();
      expect(
        names.where(
          (n) =>
              RegExp(r'^main\.[0-9a-f]{8}\.dart\.(js|wasm|mjs)$').hasMatch(n),
        ),
        hasLength(3),
      );
      expect(names, isNot(contains('main.dart.js')));
      expect(
        File('${tmp.path}/web/canvaskit/$engineRev/chromium/canvaskit.wasm')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${tmp.path}/web/canvaskit/canvaskit.wasm').existsSync(),
        isFalse,
      );
      expect(
        File('${tmp.path}/web/_headers').readAsStringSync(),
        'x https://a https://t.example;',
      );
      expect(
        File('${tmp.path}/web/.htaccess').readAsStringSync(),
        'h https://t.example',
      );
      expect(
        File('${tmp.path}/hosting/nginx/snippets/linefm-headers.conf')
            .readAsStringSync(),
        'n https://t.example',
      );
      expect(
        File('${tmp.path}/hosting/netlify.toml').readAsStringSync(),
        'csp = "a https://t.example"',
      );
      expect(
        File('${tmp.path}/hosting/vercel.json').readAsStringSync(),
        '{"value": "b $googleCastScriptSources"}',
      );
      expect(
        File('${tmp.path}/netlify.toml').readAsStringSync(),
        contains(cspPlaceholder),
      );
      expect(
        File('${tmp.path}/web/sw.js').readAsStringSync(),
        isNot(contains(buildIdPlaceholder)),
      );
      expect(File('${tmp.path}/web/index.html').readAsStringSync(), isEmpty);
      final manifest = File('${tmp.path}/web/asset-manifest.txt')
          .readAsStringSync();
      expect(manifest, contains('  sw.js'));
      expect(manifest, contains('  canvaskit/$engineRev/canvaskit.wasm'));
      expect(written, isNotEmpty);

      // Zweiter Lauf auf dieselbe Ausgabe aendert nichts mehr (idempotent).
      Map<String, String> snapshot() => <String, String>{
        for (final f in Directory(
          '${tmp.path}/web',
        ).listSync(recursive: true).whereType<File>())
          f.path.replaceAll('\\', '/').split('/web/').last: base64Encode(
            f.readAsBytesSync(),
          ),
      };
      final before = snapshot();
      runPostbuild(
        PostbuildOptions(
          webDir: Directory('${tmp.path}/web'),
          deployDir: '${tmp.path}/deploy',
          hostingOut: '${tmp.path}/hosting',
          cspConnectExtra: 'https://t.example',
        ),
      );
      expect(snapshot(), before);
      expect(
        Directory('${tmp.path}/web/canvaskit/$engineRev/$engineRev')
            .existsSync(),
        isFalse,
      );
    });

    test(
      'erneuter Build in dieselbe Ausgabe verschachtelt canvaskit nicht',
      () {
        void freshBuild(String js) {
          write('web/flutter_bootstrap.js', bootstrap());
          write('web/main.dart.js', js);
          write('web/canvaskit/canvaskit.wasm', 'ck-$js');
          write('web/canvaskit/chromium/canvaskit.wasm', 'ck2-$js');
        }

        PostbuildOptions opts() => PostbuildOptions(
          webDir: Directory('${tmp.path}/web'),
          deployDir: '${tmp.path}/none',
          targets: const <String>{},
        );

        freshBuild('v1');
        write('web/canvaskit/${'0' * 40}/alt.wasm', 'alte Revision');
        runPostbuild(opts());
        freshBuild('v2');
        runPostbuild(opts());
        runPostbuild(opts());

        final ck = Directory('${tmp.path}/web/canvaskit');
        expect(
          ck.listSync().map((e) => e.path.split(RegExp(r'[\\/]')).last),
          <String>[engineRev],
        );
        expect(
          File('${ck.path}/$engineRev/canvaskit.wasm').readAsStringSync(),
          'ck-v2',
        );
        expect(
          File('${ck.path}/$engineRev/chromium/canvaskit.wasm')
              .readAsStringSync(),
          'ck2-v2',
        );
        expect(
          Directory('${ck.path}/$engineRev/$engineRev').existsSync(),
          isFalse,
        );
        final mains = Directory('${tmp.path}/web')
            .listSync()
            .map((e) => e.path.split(RegExp(r'[\\/]')).last)
            .where((n) => n.startsWith('main.'))
            .toList();
        expect(mains, hasLength(1));
        expect(
          File('${tmp.path}/web/flutter_bootstrap.js').readAsStringSync(),
          contains(mains.single),
        );
      },
    );

    test('erneuter Lauf nach neuen Dateien setzt eine neue Build-ID', () {
      write('web/flutter_bootstrap.js', bootstrap());
      write('web/main.dart.js', 'js');
      write('web/sw.js', "const BUILD_ID = '__BUILD_ID__';");
      final opts = PostbuildOptions(
        webDir: Directory('${tmp.path}/web'),
        deployDir: '${tmp.path}/none',
        targets: const <String>{},
      );
      runPostbuild(opts);
      final first = File('${tmp.path}/web/sw.js').readAsStringSync();
      write('web/assets/fonts/fallback/notosans/v1/a.woff2', 'font');
      expect(hasFontFallback(Directory('${tmp.path}/web')), isTrue);
      expect(() => runPostbuild(opts), throwsA(isA<PostbuildException>()));
      write('web/assets/fonts/fallback/OFL.txt', 'OFL');
      runPostbuild(opts);
      final second = File('${tmp.path}/web/sw.js').readAsStringSync();
      expect(second, matches(RegExp(r"^const BUILD_ID = '[0-9a-f]{12}';$")));
      expect(second, isNot(first));
    });

    test('neues main.dart.* bei bearbeitetem Bootstrap ist ein Fehler', () {
      write('web/flutter_bootstrap.js', bootstrap());
      write('web/main.dart.js', 'js');
      final opts = PostbuildOptions(
        webDir: Directory('${tmp.path}/web'),
        deployDir: '${tmp.path}/none',
        targets: const <String>{},
      );
      runPostbuild(opts);
      write('web/main.dart.js', 'js2');
      expect(() => runPostbuild(opts), throwsA(isA<PostbuildException>()));
    });
  });

  group('renderModulePreload', () {
    const html =
        '<body>\n  <script src="analytics.js" defer></script>\n'
        '  <script src="flutter_bootstrap.js" async></script>\n</body>';

    test('puts the hashed module before the bootstrap, idempotent', () {
      final once = renderModulePreload(html, 'main.0123abcd.dart.mjs');
      expect(
        once,
        contains(
          '<link rel="modulepreload" href="main.0123abcd.dart.mjs">'
          '<!-- /linefm:modulepreload -->\n'
          '  <script src="flutter_bootstrap.js"',
        ),
      );
      expect(renderModulePreload(once, 'main.0123abcd.dart.mjs'), once);
      final next = renderModulePreload(once, 'main.ffffffff.dart.mjs');
      expect(next, isNot(contains('0123abcd')));
      expect('rel="modulepreload"'.allMatches(next), hasLength(1));
    });

    test('without a module the entry disappears', () {
      final once = renderModulePreload(html, 'main.0123abcd.dart.mjs');
      expect(renderModulePreload(once, null), html);
    });
  });

  group('precompressWeb', () {
    late Directory web;
    setUp(() => web = Directory.systemTemp.createTempSync('precompress'));
    tearDown(() => web.deleteSync(recursive: true));

    File put(String rel, String content) => File('${web.path}/$rel')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);

    test('writes smaller .gz/.br sidecars for large compressible files', () {
      final big = 'flutter ' * 2000;
      put('main.0123abcd.dart.mjs', big);
      put('assets/NOTICES', big);
      put('icons/logo.png', big);
      put('small.js', 'x');
      put('stale.js.gz', 'old');

      precompressWeb(web);

      final gz = File('${web.path}/main.0123abcd.dart.mjs.gz');
      expect(gz.existsSync(), isTrue);
      expect(utf8.decode(gzip.decode(gz.readAsBytesSync())), big);
      expect(File('${web.path}/assets/NOTICES.gz').existsSync(), isTrue);
      expect(File('${web.path}/icons/logo.png.gz').existsSync(), isFalse);
      expect(File('${web.path}/small.js.gz').existsSync(), isFalse);
      expect(File('${web.path}/stale.js.gz').existsSync(), isFalse);
      final br = File('${web.path}/main.0123abcd.dart.mjs.br');
      if (br.existsSync()) {
        expect(br.lengthSync(), lessThan(gz.lengthSync()));
      }
    });

    test('sidecars stay out of the asset manifest', () {
      put('flutter_bootstrap.js', bootstrap());
      put('main.dart.mjs', 'flutter ' * 2000);
      final opts = PostbuildOptions(
        webDir: web,
        deployDir: '${web.path}/none',
        targets: const <String>{},
      );
      runPostbuild(opts);
      runPostbuild(opts);
      final manifest = File('${web.path}/asset-manifest.txt')
          .readAsStringSync();
      expect(manifest, isNot(contains('.gz')));
      expect(manifest, isNot(contains('.br')));
      expect(
        web.listSync().whereType<File>().where((f) => f.path.endsWith('.gz')),
        isNotEmpty,
      );
      runPostbuild(
        PostbuildOptions(
          webDir: web,
          deployDir: '${web.path}/none',
          targets: const <String>{},
          precompress: false,
        ),
      );
      expect(
        web
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => isPrecompressedSidecar(f.path)),
        isEmpty,
      );
    });
  });
}
