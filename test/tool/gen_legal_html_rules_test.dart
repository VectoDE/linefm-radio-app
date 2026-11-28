import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gen_legal_html.dart';
import 'gen_legal_html_helpers.dart';

void main() {
  group('Strict-Dateien', () {
    test('findet Platzhalter in Dateien, fehlende Dateien zaehlen nicht', () {
      final Directory tmp = Directory.systemTemp.createTempSync('legal');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final File a = File('${tmp.path}/a.md')
        ..writeAsStringSync('Kontakt: {{SECURITY_KONTAKT}}');
      final File b = File('${tmp.path}/b.md')..writeAsStringSync('fertig');
      final Map<String, Set<String>> open = openPlaceholdersInFiles(<String>[
        a.path,
        b.path,
        '${tmp.path}/fehlt.md',
      ]);
      expect(open.keys, <String>[a.path]);
      expect(open[a.path], <String>{'SECURITY_KONTAKT'});
    });

    test('Barrierefreiheit und Sicherheitskontakt sind erfasst', () {
      expect(
        strictFiles,
        containsAll(<String>[
          'docs/BARRIEREFREIHEIT.md',
          'SECURITY.md',
          'web/.well-known/security.txt',
        ]),
      );
    });
  });

  group('Pflicht-Regeln', () {
    final Map<String, Object?> registry =
        (jsonDecode(File('assets/legal/placeholders.json').readAsStringSync())
                as Map<String, Object?>)['placeholders']!
            as Map<String, Object?>;

    test('leere und Leerzeichen-Werte zaehlen als offen', () {
      expect(
        nonBlankValues(<String, String>{'A': '', 'B': '  ', 'C': 'x'}),
        <String, String>{'C': 'x'},
      );
      final Map<String, Object?> doc = <String, Object?>{
        'blocks': <Object?>[
          <String, Object?>{'type': 'p', 'text': '{{A}} {{B}} {{C}}'},
        ],
      };
      expect(
        openPlaceholders(doc, <String>{}, <String, String>{
          'A': '',
          'B': ' 	',
          'C': 'x',
        }),
        <String>{'A', 'B'},
      );
    });

    test('leerer Pflichtwert ergibt offene Pflichtangabe (Exit 1)', () {
      final Map<String, String> values = nonBlankValues(<String, String>{
        for (final String k in registry.keys)
          k: k == 'BETREIBER_NAME' ? ' ' : 'X',
      });
      final Set<String> open = <String>{};
      for (final String kind in <String>['impressum', 'datenschutz']) {
        open.addAll(openPlaceholders(legalDoc('de', kind), <String>{}, values));
      }
      expect(requiredOpen(open, registry, <String>{}), <String>[
        'BETREIBER_NAME',
      ]);
    });

    test('nicht registrierte Platzhalter sind Pflicht', () {
      expect(
        isRequiredPlaceholder('GIBT_ES_NICHT', registry, <String>{}),
        isTrue,
      );
      expect(isRequiredPlaceholder('USTID', registry, <String>{}), isFalse);
    });

    test('required_if: Anbieterangaben bei aktiver Telemetrie Pflicht', () {
      expect(
        isRequiredPlaceholder('UMAMI_BETREIBER', registry, <String>{}),
        isFalse,
      );
      expect(
        isRequiredPlaceholder('UMAMI_BETREIBER', registry, <String>{'umami'}),
        isTrue,
      );
      expect(
        isRequiredPlaceholder('UMAMI_BETREIBER', registry, <String>{'sentry'}),
        isFalse,
      );
      expect(
        isRequiredPlaceholder('SENTRY_BETREIBER', registry, <String>{'sentry'}),
        isTrue,
      );
      expect(
        isRequiredPlaceholder('TELEMETRIE_AUFBEWAHRUNG', registry, <String>{
          'firebase',
        }),
        isTrue,
      );
    });

    test('Datenschutz mit Umami ohne Betreiber: Pflicht offen', () {
      final Map<String, String> values = <String, String>{
        for (final String k in registry.keys)
          if (k != 'UMAMI_BETREIBER' && k != 'TELEMETRIE_AUFBEWAHRUNG') k: 'X',
      };
      final Set<String> p = <String>{'umami'};
      final Set<String> open = openPlaceholders(
        legalDoc('de', 'datenschutz'),
        p,
        values,
      );
      expect(requiredOpen(open, registry, p), <String>[
        'TELEMETRIE_AUFBEWAHRUNG',
        'UMAMI_BETREIBER',
      ]);
      expect(requiredOpen(open, registry, <String>{}), isEmpty);
    });
  });

  group('Platzhalter-Erkennung wie im Store-Check', () {
    test('Muster ist identisch mit legal_store_check.py', () {
      final String py = File('tool/legal_store_check.py').readAsStringSync();
      final String block = RegExp(
        r'PLACEHOLDER_PATTERN = \(\n((?:    r"[^\n]*"\n)+)\)',
      ).firstMatch(py)!.group(1)!;
      final String pattern = RegExp(r'r"([^\n]*)"')
          .allMatches(block)
          .map((Match m) => m.group(1))
          .join();
      expect(pattern, placeholderPattern);
    });

    test('lockere Schreibweisen werden erkannt', () {
      final Map<String, String> cases = <String, String>{
        '{{BETREIBER_NAME}}': 'BETREIBER_NAME',
        '{{ BETREIBER_NAME }}': 'BETREIBER_NAME',
        '{{X-Y}}': 'X-Y',
        '{{STRASSE_ÄÖÜ}}': 'STRASSE_ÄÖÜ',
        '\uFF5B\uFF5BVOLLBREIT\uFF5D\uFF5D': 'VOLLBREIT',
      };
      for (final MapEntry<String, String> c in cases.entries) {
        expect(findPlaceholders('a ${c.key} b'), <String>{c.value});
      }
      expect(findPlaceholders('{einfach} {{\n}}'), isEmpty);
    });

    test('Escapes im JSON fallen nach dem Dekodieren auf', () {
      const String raw =
          r'{"blocks":[{"type":"p","text":"\u007b\u007bVERSTECKT\u007d\u007d"}]}';
      expect(findPlaceholders(raw), isEmpty);
      final Map<String, Object?> doc = jsonDecode(raw) as Map<String, Object?>;
      expect(openPlaceholders(doc, <String>{}, <String, String>{}), <String>{
        'VERSTECKT',
      });
    });

    test('ersetzt auch locker geschriebene Platzhalter', () {
      expect(substitute('{{ A }} {{A}}', <String, String>{'A': 'x'}), 'x x');
    });

    test('nur nicht-leere Strings, ohne Cf/Zs', () {
      expect(
        nonBlankValues(<String, String>{
          'A': '\u200B',
          'B': '\uFEFF\u00A0',
          'C': '\u2009\u3000',
          'D': '\u200Bx',
        }),
        <String, String>{'D': '\u200Bx'},
      );
      expect(
        stringValues(<String, Object?>{
          'A': null,
          'B': 0,
          'C': false,
          'D': <String>['x'],
          'E': 'x',
        }),
        <String, String>{'E': 'x'},
      );
    });

    test('Link-Ziele nur http(s) und mailto', () {
      expect(isSafeLinkUrl('https://example.org/x'), isTrue);
      expect(isSafeLinkUrl('mailto:a@b.de'), isTrue);
      for (final String bad in <String>[
        'javascript:alert(1)',
        'JAVASCRIPT:alert(1)',
        'data:text/html,x',
        '//example.org',
        '{{URL}}',
        'https://',
        '',
      ]) {
        expect(isSafeLinkUrl(bad), isFalse, reason: bad);
      }
      final String html = renderPage(
        <String, Object?>{
          'title': 'T',
          'blocks': <Object?>[
            <String, Object?>{
              'type': 'link',
              'text': 'Klick',
              'url': 'javascript:alert(1)',
            },
          ],
        },
        kind: 'impressum',
        lang: 'de',
        baseUrl: 'https://app.linefm.de',
        providers: <String>{},
        values: <String, String>{},
      );
      expect(html, isNot(contains('javascript:')));
      expect(html, contains('<p>Klick</p>'));
    });

    test('Basis-URL wird geprueft und escaped', () {
      expect(checkedBaseUrl('https://app.linefm.de'), 'https://app.linefm.de');
      for (final String bad in <String>[
        'javascript:alert(1)',
        'app.linefm.de',
        'https://x.de/?a=1',
        'https://x.de/#f',
      ]) {
        expect(() => checkedBaseUrl(bad), throwsFormatException, reason: bad);
      }
      final String html = renderPage(
        <String, Object?>{'title': 'T', 'blocks': <Object?>[]},
        kind: 'impressum',
        lang: 'de',
        baseUrl: 'https://x.de/a"b',
        providers: <String>{},
        values: <String, String>{},
      );
      expect(html, isNot(contains('a"b')));
      expect(html, contains('a&quot;b'));
    });

    test('--providers lehnt Unbekanntes ab', () {
      expect(parseProviders(' umami, sentry ,'), <String>{'umami', 'sentry'});
      expect(() => parseProviders('umami,matomo'), throwsFormatException);
    });

    test('ga4 ist bekannt, zaehlt aber nicht als telemetry', () {
      expect(parseProviders('ga4,umami'), <String>{'ga4', 'umami'});
      expect(requirementMet('telemetry', <String>{'ga4'}), isFalse);
      expect(requirementMet('!telemetry', <String>{'ga4'}), isTrue);
      expect(requirementMet('ga4', <String>{'ga4'}), isTrue);
    });
  });
}
