import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/web_postbuild.dart';
import 'web_postbuild_helpers.dart';

void main() {
  group('style-src hashes', () {
    test('empty string hash matches the CSP reference value', () {
      expect(
        cspSha256(''),
        "'sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU='",
      );
    });

    test('collects every inline style block', () {
      const html =
          '<style>a{}</style><noscript><style id="x">b{}</style></noscript>';
      expect(
        inlineStyleHashes(html),
        <String>[cspSha256('a{}'), cspSha256('b{}')]..sort(),
      );
    });

    test("replaces 'unsafe-inline' only in style-src", () {
      const csp =
          "Content-Security-Policy: default-src 'self'; script-src 'self'; "
          "style-src 'self' 'unsafe-inline'; img-src 'self'";
      final out = renderStyleHashes(csp, <String>["'nonce-N'", "'sha256-A'"]);
      expect(out, contains("style-src 'self' 'nonce-N' 'sha256-A';"));
      expect(out, isNot(contains('unsafe-inline')));
      expect(out, contains("script-src 'self';"));
    });

    test('leaves style-src-elem and style-src-attr untouched', () {
      const csp =
          "style-src-elem 'self' 'unsafe-inline'; "
          "style-src-attr 'unsafe-inline'";
      expect(renderStyleHashes(csp, <String>["'sha256-A'"]), csp);
    });

    test("refuses to drop 'unsafe-inline' without a nonce", () {
      expect(
        () => renderStyleHashes("style-src 'self' 'unsafe-inline'", <String>[
          "'sha256-A'",
        ]),
        throwsA(isA<PostbuildException>()),
      );
    });

    test('finds the nonce of an already built bootstrap', () {
      final nonce = newStyleNonce();
      expect(existingStyleNonce("var c = {nonce: '$nonce'};"), nonce);
      expect(
        existingStyleNonce("var c = {nonce: '$cspStyleNoncePlaceholder'};"),
        isNull,
      );
    });
  });

  group('style nonce', () {
    test('128 bit, base64, differs per call', () {
      final a = newStyleNonce();
      expect(base64.decode(a), hasLength(16));
      expect(newStyleNonce(), isNot(a));
    });

    test('fills the bootstrap placeholder, null without it', () {
      expect(
        renderStyleNonce("var c = {nonce: '$cspStyleNoncePlaceholder'};", 'N'),
        "var c = {nonce: 'N'};",
      );
      expect(renderStyleNonce('var c = {};', 'N'), isNull);
    });

    test('the bootstrap template carries the placeholder', () {
      expect(
        File('web/flutter_bootstrap.js').readAsStringSync(),
        contains("nonce: '$cspStyleNoncePlaceholder'"),
      );
    });
  });

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
        bootstrap(),
        renamedMain: <String, String>{
          'main.dart.wasm': 'main.aaaaaaaa.dart.wasm',
          'main.dart.mjs': 'main.bbbbbbbb.dart.mjs',
          'main.dart.js': 'main.cccccccc.dart.js',
        },
        engineRevision: engineRev,
      );
      expect(out, contains('"mainWasmPath":"main.aaaaaaaa.dart.wasm"'));
      expect(out, contains('"jsSupportRuntimePath":"main.bbbbbbbb.dart.mjs"'));
      expect(out, contains('"mainJsPath":"main.cccccccc.dart.js"'));
      expect(out, contains('"main.aaaaaaaa.dart.wasm":"bb"'));
      expect(out, isNot(contains('"main.dart.wasm"')));
      expect(
        out,
        contains("config.canvasKitBaseUrl = 'canvaskit/$engineRev/';"),
      );
    });

    test('fehlende Marke ist ein Fehler', () {
      expect(
        () => rewriteBootstrap(
          bootstrap().replaceFirst('/*__CANVASKIT_BASE_URL__*/', ''),
          renamedMain: <String, String>{},
          engineRevision: engineRev,
        ),
        throwsA(isA<PostbuildException>()),
      );
    });
  });
}
