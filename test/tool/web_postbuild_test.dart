import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/web_postbuild.dart';

const String _rev = '371f77202a73e8dff57a8b3bff75bca55c090aee';

String _bootstrap() =>
    '''
(function(){})();
if (!window._flutter) {
  window._flutter = {};
}
_flutter.buildConfig = {"engineRevision":"$_rev","wasmHashes":{"skwasm.wasm":"aa","main.dart.wasm":"bb"},"builds":[{"compileTarget":"dart2wasm","renderer":"skwasm","mainWasmPath":"main.dart.wasm","jsSupportRuntimePath":"main.dart.mjs"},{"compileTarget":"dart2js","renderer":"canvaskit","mainJsPath":"main.dart.js"}],"useLocalCanvasKit":true};
(function () {
  var config = {};
  /*__CANVASKIT_BASE_URL__*/
})();
''';

void main() {
  group('sha256Hex', () {
    test('bekannte Testvektoren', () {
      expect(
        sha256Hex(<int>[]),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(
        sha256Hex(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(
        sha256Hex(
          utf8.encode(
            'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq',
          ),
        ),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
    });
  });

  group('deriveCspConnectExtra', () {
    test('leer ohne Telemetrie', () {
      expect(
        deriveCspConnectExtra(<String, dynamic>{'FIREBASE_ENABLED': false}),
        '',
      );
    });

    test('Umami, Sentry und Firebase', () {
      final extra = deriveCspConnectExtra(<String, dynamic>{
        'UMAMI_URL': 'https://stats.example.org/script.js',
        'SENTRY_DSN': 'https://key@o1.ingest.sentry.io/42',
        'FIREBASE_ENABLED': true,
      });
      expect(extra, contains('https://stats.example.org'));
      expect(extra, contains('https://o1.ingest.sentry.io'));
      expect(extra, contains('https://*.googleapis.com'));
      expect(extra, isNot(contains('key@')));
    });
  });

  group('Platzhalter', () {
    test('CSP-Platzhalter ohne Rest-Leerzeichen', () {
      expect(
        renderCspPlaceholder('a https://x $cspPlaceholder; b', ''),
        'a https://x; b',
      );
      expect(
        renderCspPlaceholder(
          'a https://x $cspPlaceholder; b',
          'https://t.example',
        ),
        'a https://x https://t.example; b',
      );
    });

    test('Search-Console-Tag wird gesetzt oder entfernt', () {
      const html =
          '<head>\n  <meta name="google-site-verification" content="__GSC_VERIFICATION__">\n</head>';
      expect(renderGscVerification(html, ''), '<head>\n</head>');
      expect(
        renderGscVerification(html, 'abc"x'),
        contains('content="abc&quot;x"'),
      );
    });

    test('Basis-URL wird nur bei Abweichung ersetzt', () {
      expect(
        rewriteBaseUrl('$defaultBaseUrl/x', defaultBaseUrl),
        '$defaultBaseUrl/x',
      );
      expect(
        rewriteBaseUrl('$defaultBaseUrl/x', 'https://stage.example/'),
        'https://stage.example/x',
      );
    });
  });

  group('rewriteBootstrap', () {
    test('Pfade, Hash-Schluessel und CanvasKit-URL', () {
      final out = rewriteBootstrap(
        _bootstrap(),
        renamedMain: <String, String>{
          'main.dart.wasm': 'main.aaaaaaaa.dart.wasm',
          'main.dart.mjs': 'main.bbbbbbbb.dart.mjs',
          'main.dart.js': 'main.cccccccc.dart.js',
        },
        engineRevision: _rev,
      );
      expect(out, contains('"mainWasmPath":"main.aaaaaaaa.dart.wasm"'));
      expect(out, contains('"jsSupportRuntimePath":"main.bbbbbbbb.dart.mjs"'));
      expect(out, contains('"mainJsPath":"main.cccccccc.dart.js"'));
      expect(out, contains('"main.aaaaaaaa.dart.wasm":"bb"'));
      expect(out, isNot(contains('"main.dart.wasm"')));
      expect(out, contains("config.canvasKitBaseUrl = 'canvaskit/$_rev/';"));
    });

    test('fehlende Marke ist ein Fehler', () {
      expect(
        () => rewriteBootstrap(
          _bootstrap().replaceFirst('/*__CANVASKIT_BASE_URL__*/', ''),
          renamedMain: <String, String>{},
          engineRevision: _rev,
        ),
        throwsA(isA<PostbuildException>()),
      );
    });
  });

  group('runPostbuild', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('postbuild_test'));
    tearDown(() => tmp.deleteSync(recursive: true));

    void write(String path, String content) => File('${tmp.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);

    test('Ende-zu-Ende auf einer Mini-Ausgabe', () {
      write('web/flutter_bootstrap.js', _bootstrap());
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
        File('${tmp.path}/web/canvaskit/$_rev/chromium/canvaskit.wasm')
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
        File('${tmp.path}/web/sw.js').readAsStringSync(),
        isNot(contains(buildIdPlaceholder)),
      );
      expect(File('${tmp.path}/web/index.html').readAsStringSync(), isEmpty);
      final manifest = File('${tmp.path}/web/asset-manifest.txt')
          .readAsStringSync();
      expect(manifest, contains('  sw.js'));
      expect(manifest, contains('  canvaskit/$_rev/canvaskit.wasm'));
      expect(written, isNotEmpty);

      // Zweiter Lauf auf dieselbe Ausgabe aendert nichts mehr (idempotent).
      Map<String, String> snapshot() => <String, String>{
        for (final f in Directory(
          '${tmp.path}/web',
        ).listSync(recursive: true).whereType<File>())
          f.path.replaceAll('\\', '/').split('/web/').last: f
              .readAsStringSync(),
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
        Directory('${tmp.path}/web/canvaskit/$_rev/$_rev').existsSync(),
        isFalse,
      );
    });

    test(
      'erneuter Build in dieselbe Ausgabe verschachtelt canvaskit nicht',
      () {
        void freshBuild(String js) {
          write('web/flutter_bootstrap.js', _bootstrap());
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
          <String>[_rev],
        );
        expect(
          File('${ck.path}/$_rev/canvaskit.wasm').readAsStringSync(),
          'ck-v2',
        );
        expect(
          File('${ck.path}/$_rev/chromium/canvaskit.wasm').readAsStringSync(),
          'ck2-v2',
        );
        expect(Directory('${ck.path}/$_rev/$_rev').existsSync(), isFalse);
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
      write('web/flutter_bootstrap.js', _bootstrap());
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
      write('web/flutter_bootstrap.js', _bootstrap());
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

  group('Header-Konsistenz der Hosting-Dateien', () {
    String between(String text, RegExp re) => re.firstMatch(text)!.group(1)!;

    test('CSP und Security-Header sind in allen Zielen identisch', () {
      final nginx = File('deploy/nginx/snippets/linefm-headers.conf')
          .readAsStringSync();
      final plesk = File('deploy/plesk/nginx-additional.conf')
          .readAsStringSync();
      final htaccess = File('deploy/plesk/.htaccess').readAsStringSync();
      final cloudflare = File('deploy/cloudflare/_headers').readAsStringSync();

      final nginxHeaders = RegExp(r'add_header (\S+) "(.*)" always;')
          .allMatches(nginx)
          .map((m) => '${m.group(1)}: ${m.group(2)}')
          .toList();
      expect(nginxHeaders, hasLength(8));

      final pleskHeaders = RegExp(r'add_header (\S+) "(.*)" always;')
          .allMatches(plesk)
          .map((m) => '${m.group(1)}: ${m.group(2)}')
          .toList();
      final apacheHeaders =
          RegExp(r'Header always set (\S+) "(.*)"$', multiLine: true)
              .allMatches(htaccess)
              .where((m) => m.group(1) != 'Cache-Control')
              .map((m) => '${m.group(1)}: ${m.group(2)}')
              .toList();
      final cfBlock = between(
        cloudflare,
        RegExp(r'^/\*\n((?:  .*\n)+)', multiLine: true),
      );
      final cfHeaders = cfBlock
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => l.trim())
          .toList();
      // Pages-only lines: comments and the detach of the default CORS header.
      expect(cfHeaders, contains('! Access-Control-Allow-Origin'));
      cfHeaders.removeWhere((l) => l.startsWith('#') || l.startsWith('!'));

      expect(pleskHeaders, nginxHeaders);
      expect(apacheHeaders, nginxHeaders);
      expect(cfHeaders, nginxHeaders);
    });

    test('CSP enthaelt die Pflicht-Direktiven', () {
      final nginx = File('deploy/nginx/snippets/linefm-headers.conf')
          .readAsStringSync();
      for (final d in <String>[
        "default-src 'self'",
        "script-src 'self' 'wasm-unsafe-eval'",
        "frame-ancestors 'none'",
        "object-src 'none'",
        'upgrade-insecure-requests',
        cspPlaceholder,
      ]) {
        expect(nginx, contains(d));
      }
      expect(nginx, isNot(contains("'unsafe-eval'")));
      expect(
        RegExp(r"script-src[^;]*'unsafe-inline'").hasMatch(nginx),
        isFalse,
      );
    });
  });

  group('Sitemap lastmod (SEO-03)', () {
    test('setzt jedes lastmod auf das Build-Datum, idempotent', () {
      const xml =
          '<url><loc>a</loc><lastmod>2020-01-01</lastmod></url>'
          '<url><lastmod>x</lastmod></url>';
      final date = DateTime.utc(2026, 11, 19, 23, 59);
      final once = renderSitemapLastmod(xml, date);
      expect(once, contains('<lastmod>2026-11-19</lastmod>'));
      expect(once, isNot(contains('2020-01-01')));
      expect(renderSitemapLastmod(once, date), once);
    });

    test('SOURCE_DATE_EPOCH bestimmt das Datum', () {
      expect(
        buildDate(<String, String>{'SOURCE_DATE_EPOCH': '1795046400'}),
        DateTime.utc(2026, 11, 19),
      );
    });

    test('Copyright-Jahre: erstes Jahr bis Build-Jahr', () {
      expect(copyrightYears(DateTime.utc(2026, 11, 19)), '2026');
      expect(copyrightYears(DateTime.utc(2027, 1, 1)), '2026-2027');
      final index = File('web/index.html').readAsStringSync();
      expect(index, contains(copyrightYearsPlaceholder));
    });

    test('eingecheckte Sitemap: lastmod, kein hreflang en', () {
      final xml = File('web/sitemap.xml').readAsStringSync();
      expect(xml, contains('<lastmod>'));
      expect(xml, isNot(contains('hreflang="en"')));
      expect(
        File('web/index.html').readAsStringSync(),
        isNot(contains('hreflang="en"')),
      );
    });
  });

  group('App-Links .well-known (L3-01)', () {
    late Directory web;
    const fp =
        'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:'
        'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99';
    setUp(() {
      web = Directory.systemTemp.createTempSync('applinks');
      Directory('${web.path}/.well-known').createSync();
      for (final name in appLinkTemplates.keys) {
        File('web/.well-known/$name').copySync('${web.path}/.well-known/$name');
      }
    });
    tearDown(() => web.deleteSync(recursive: true));

    test('Vorlagen im Repo sind gueltiges JSON mit Platzhalter', () {
      for (final e in appLinkTemplates.entries) {
        final text = File('web/.well-known/${e.key}').readAsStringSync();
        expect(text, contains('{{${e.value}}}'));
        expect(() => jsonDecode(text), returnsNormally);
      }
    });

    test('fuellt beide Dateien aus der Umgebung, gueltiges JSON', () {
      final done = renderAppLinks(
        web,
        const <String, dynamic>{},
        strict: true,
        env: <String, String>{
          'ANDROID_CERT_SHA256': '${fp.toLowerCase()}, $fp',
          'APPLE_TEAM_ID': 'ABCDE12345',
        },
      );
      expect(done, hasLength(2));
      final links = jsonDecode(
        File('${web.path}/.well-known/assetlinks.json').readAsStringSync(),
      ) as List<dynamic>;
      expect(
        (links.single
            as Map<String, dynamic>)['target']['sha256_cert_fingerprints'],
        <String>[fp],
        reason: 'doppelter Fingerprint (Gross/klein) nur einmal',
      );
      final aasa = jsonDecode(
        File('${web.path}/.well-known/apple-app-site-association')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(aasa['applinks']['details'][0]['appIDs'], <String>[
        'ABCDE12345.de.linefm.app',
      ]);
    });

    test('App-Signatur und Upload-Schluessel: beide Fingerprints (R4-C5)', () {
      final upload = List<String>.filled(32, 'CD').join(':');
      renderAppLinks(
        web,
        const <String, dynamic>{},
        strict: true,
        env: <String, String>{
          'ANDROID_CERT_SHA256': ' $fp ,${upload.toLowerCase()},',
          'APPLE_TEAM_ID': 'ABCDE12345',
        },
      );
      final links = jsonDecode(
        File('${web.path}/.well-known/assetlinks.json').readAsStringSync(),
      ) as List<dynamic>;
      expect(
        (links.single
            as Map<String, dynamic>)['target']['sha256_cert_fingerprints'],
        <String>[fp, upload],
      );
    });

    test('Konfiguration als Quelle, Umgebung hat Vorrang', () {
      renderAppLinks(
        web,
        const <String, dynamic>{'APPLE_TEAM_ID': 'ZZZZZZZZZZ'},
        strict: false,
        env: <String, String>{'APPLE_TEAM_ID': 'ABCDE12345'},
      );
      expect(
        File('${web.path}/.well-known/apple-app-site-association')
            .readAsStringSync(),
        contains('ABCDE12345.de.linefm.app'),
      );
    });

    test('ohne Werte: Warnung und Datei entfernt', () {
      final done = renderAppLinks(
        web,
        const <String, dynamic>{},
        strict: false,
        env: const <String, String>{'APPLE_TEAM_ID': '  '},
      );
      expect(done, isEmpty);
      expect(
        File('${web.path}/.well-known/assetlinks.json').existsSync(),
        isFalse,
      );
      expect(
        File('${web.path}/.well-known/apple-app-site-association').existsSync(),
        isFalse,
      );
    });

    test('ohne Werte mit --strict: Abbruch', () {
      expect(
        () => renderAppLinks(
          web,
          const <String, dynamic>{},
          strict: true,
          env: const <String, String>{},
        ),
        throwsA(isA<PostbuildException>()),
      );
    });

    test('falsches Format ist immer ein Fehler', () {
      expect(
        () => renderAppLinks(
          web,
          const <String, dynamic>{},
          strict: false,
          env: const <String, String>{
            'ANDROID_CERT_SHA256': 'AA:BB',
            'APPLE_TEAM_ID': 'ABCDE12345',
          },
        ),
        throwsA(isA<PostbuildException>()),
      );
    });

    test('Hosting-Ziele liefern die AASA als application/json', () {
      expect(
        File('deploy/nginx/snippets/linefm-locations.conf').readAsStringSync(),
        contains('location = /.well-known/apple-app-site-association'),
      );
      expect(
        File('deploy/plesk/nginx-additional.conf').readAsStringSync(),
        contains('location = /.well-known/apple-app-site-association'),
      );
      expect(
        File('deploy/plesk/.htaccess').readAsStringSync(),
        contains('ForceType application/json'),
      );
      expect(
        File('deploy/cloudflare/_headers').readAsStringSync(),
        contains(
          '/.well-known/apple-app-site-association\n'
          '  Content-Type: application/json',
        ),
      );
    });
  });

  group('Google Tag Manager / GA4 (P31)', () {
    const ids = <String, dynamic>{
      'GTM_ID': 'GTM-TEST000',
      'GA4_MEASUREMENT_ID': 'G-TEST000000',
    };

    test('ohne IDs keine Google-Quellen, CSP bleibt streng', () {
      const cfg = <String, dynamic>{'GTM_ID': '', 'GA4_MEASUREMENT_ID': ' '};
      expect(googleTagConfigured(cfg), isFalse);
      expect(deriveCspScriptExtra(cfg), isEmpty);
      expect(deriveCspImgExtra(cfg), isEmpty);
      expect(deriveCspConnectExtra(cfg), isNot(contains('google')));
    });

    test('mit IDs: script-, img- und connect-src erweitert', () {
      expect(googleTagConfigured(ids), isTrue);
      expect(deriveCspScriptExtra(ids), 'https://www.googletagmanager.com');
      expect(
        deriveCspImgExtra(ids),
        contains('https://*.google-analytics.com'),
      );
      expect(
        deriveCspConnectExtra(ids),
        allOf(
          contains('https://*.google-analytics.com'),
          contains('https://*.analytics.google.com'),
          contains('https://www.googletagmanager.com'),
        ),
      );
      expect(
        googleTagConfigured(<String, dynamic>{
          'GA4_MEASUREMENT_ID': 'G-AB12CD34',
        }),
        isTrue,
      );
    });

    test('ungueltige ID bricht ab', () {
      expect(
        () => googleTagConfigured(<String, dynamic>{'GTM_ID': 'GTM-x"; evil'}),
        throwsA(isA<PostbuildException>()),
      );
    });

    test('alle Hosting-Dateien tragen alle drei CSP-Platzhalter', () {
      for (final path in <String>[
        'deploy/cloudflare/_headers',
        'deploy/nginx/snippets/linefm-headers.conf',
        'deploy/plesk/.htaccess',
        'deploy/plesk/nginx-additional.conf',
      ]) {
        final text = File(path).readAsStringSync();
        expect(
          text,
          contains("'wasm-unsafe-eval' $cspScriptPlaceholder;"),
          reason: path,
        );
        expect(
          text,
          contains('https://radiogruppe.de $cspImgPlaceholder;'),
          reason: path,
        );
        expect(text, contains(cspPlaceholder), reason: path);
      }
    });

    test('Platzhalter verschwinden ohne IDs spurlos', () {
      const csp =
          "script-src 'self' 'wasm-unsafe-eval' __CSP_SCRIPT_EXTRA__; img-src 'self' __CSP_IMG_EXTRA__;";
      final out = renderCspPlaceholder(
        renderCspPlaceholder(csp, '', placeholder: cspScriptPlaceholder),
        '',
        placeholder: cspImgPlaceholder,
      );
      expect(out, "script-src 'self' 'wasm-unsafe-eval'; img-src 'self';");
    });
  });
}
