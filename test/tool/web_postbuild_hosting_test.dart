import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/web_postbuild.dart';

void main() {
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

  group('Sitemap lastmod', () {
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
      expect(copyrightYears(DateTime.utc(2027)), '2026-2027');
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

  group('App-Links .well-known', () {
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
        ((links.single as Map<String, dynamic>)['target']
            as Map<String, dynamic>)['sha256_cert_fingerprints'],
        <String>[fp],
        reason: 'doppelter Fingerprint (Gross/klein) nur einmal',
      );
      final aasa = jsonDecode(
        File('${web.path}/.well-known/apple-app-site-association')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final applinks = aasa['applinks'] as Map<String, dynamic>;
      final details =
          (applinks['details'] as List<dynamic>).first as Map<String, dynamic>;
      expect(details['appIDs'], <String>['ABCDE12345.de.linefm.app']);
    });

    test('App-Signatur und Upload-Schluessel: beide Fingerprints', () {
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
        ((links.single as Map<String, dynamic>)['target']
            as Map<String, dynamic>)['sha256_cert_fingerprints'],
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

  group('Google Tag Manager / GA4', () {
    const ids = <String, dynamic>{
      'GTM_ID': 'GTM-TEST000',
      'GA4_MEASUREMENT_ID': 'G-TEST000000',
    };

    test('ohne IDs keine Google-Quellen, CSP bleibt streng', () {
      const cfg = <String, dynamic>{'GTM_ID': '', 'GA4_MEASUREMENT_ID': ' '};
      expect(googleTagConfigured(cfg), isFalse);
      // Only the Cast host (consent-gated in web/cast.js), no tag manager.
      expect(deriveCspScriptExtra(cfg), 'https://www.gstatic.com');
      expect(deriveCspImgExtra(cfg), isEmpty);
      expect(deriveCspConnectExtra(cfg), isNot(contains('google')));
    });

    test('mit IDs: script-, img- und connect-src erweitert', () {
      expect(googleTagConfigured(ids), isTrue);
      expect(
        deriveCspScriptExtra(ids),
        'https://www.gstatic.com https://www.googletagmanager.com',
      );
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
          contains('https://assets.laut.fm $cspImgPlaceholder;'),
          reason: path,
        );
        expect(text, isNot(contains('radiogruppe.de')), reason: path);
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
