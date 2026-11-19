import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gen_legal_html.dart';

Map<String, Object?> _doc(String lang, String kind) =>
    jsonDecode(File('assets/legal/$lang/$kind.json').readAsStringSync())
        as Map<String, Object?>;

void main() {
  group('requirementMet', () {
    test('ohne requires immer sichtbar', () {
      expect(requirementMet(null, <String>{}), isTrue);
    });
    test('einzelner Anbieter', () {
      expect(requirementMet('umami', <String>{'umami'}), isTrue);
      expect(requirementMet('umami', <String>{'sentry'}), isFalse);
    });
    test('telemetry = mindestens ein Anbieter', () {
      expect(requirementMet('telemetry', <String>{}), isFalse);
      expect(requirementMet('telemetry', <String>{'firebase'}), isTrue);
      expect(requirementMet('!telemetry', <String>{}), isTrue);
      expect(requirementMet('!telemetry', <String>{'sentry'}), isFalse);
    });
    test('Liste = UND', () {
      expect(
        requirementMet(<String>['umami', 'sentry'], <String>{'umami'}),
        isFalse,
      );
    });
  });

  group('Platzhalter', () {
    test('substitute ersetzt bekannte, laesst unbekannte', () {
      expect(
        substitute('{{A}} und {{B}}', <String, String>{'A': 'x'}),
        'x und {{B}}',
      );
    });
    test('substituteJsonText escaped Werte', () {
      expect(
        substituteJsonText('"{{A}}"', <String, String>{'A': 'a"b\nc'}),
        r'"a\"b\nc"',
      );
    });
    test('inlineHtml escaped, markiert offene Platzhalter, setzt br', () {
      final String html = inlineHtml('<b>{{A}}\n{{B}}', <String, String>{
        'A': 'x&y',
      });
      expect(html, contains('&lt;b&gt;x&amp;y<br>'));
      expect(html, contains('<mark class="ph">{{B}}</mark>'));
    });
  });

  group('Rechtstexte', () {
    test('de und en haben gleiche Struktur und gueltige Blocktypen', () {
      for (final String kind in <String>['impressum', 'datenschutz']) {
        final List<Object?> de = _doc('de', kind)['blocks']! as List<Object?>;
        final List<Object?> en = _doc('en', kind)['blocks']! as List<Object?>;
        expect(en.length, de.length, reason: kind);
        for (int i = 0; i < de.length; i++) {
          final Map<String, Object?> a = de[i]! as Map<String, Object?>;
          final Map<String, Object?> b = en[i]! as Map<String, Object?>;
          expect(b['type'], a['type'], reason: '$kind #$i');
          expect(b['requires'], a['requires'], reason: '$kind #$i');
          expect(
            findPlaceholders('${b['text']}${b['items']}'),
            findPlaceholders('${a['text']}${a['items']}'),
            reason: '$kind #$i Platzhalter',
          );
          expect(<String>[
            'h1',
            'h2',
            'p',
            'ul',
            'link',
            'mail',
          ], contains(a['type']));
        }
      }
    });

    test('alle Platzhalter sind in placeholders.json beschrieben', () {
      final Map<String, Object?> meta = jsonDecode(
        File('assets/legal/placeholders.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final Set<String> known = (meta['placeholders']! as Map<String, Object?>)
          .keys
          .toSet();
      final Set<String> used = <String>{};
      for (final String lang in <String>['de', 'en']) {
        for (final String kind in <String>['impressum', 'datenschutz']) {
          used.addAll(
            findPlaceholders(
              File('assets/legal/$lang/$kind.json').readAsStringSync(),
            ),
          );
        }
      }
      expect(used.difference(known), isEmpty);
      expect(known.difference(used), isEmpty);
    });

    test('Datenschutz blendet Telemetrie je Anbieter ein und aus', () {
      final Map<String, Object?> doc = _doc('de', 'datenschutz');
      String render(Set<String> p) => renderPage(
        doc,
        kind: 'datenschutz',
        lang: 'de',
        baseUrl: 'https://app.linefm.de',
        providers: p,
        values: const <String, String>{},
      );
      final String none = render(<String>{});
      expect(none, isNot(contains('Umami')));
      expect(none, isNot(contains('Crashlytics')));
      expect(none, contains('sendet keine Statistik'));
      final String umami = render(<String>{'umami'});
      expect(umami, contains('Umami (Nutzungsstatistik)'));
      expect(umami, isNot(contains('Crashlytics')));
      expect(umami, isNot(contains('sendet keine Statistik')));
      expect(render(<String>{'firebase'}), contains('Crashlytics'));
    });

    test('Seite: Grundgeruest, hreflang, noindex bei offenen Platzhaltern', () {
      final String html = renderPage(
        _doc('en', 'impressum'),
        kind: 'impressum',
        lang: 'en',
        baseUrl: 'https://app.linefm.de/',
        providers: <String>{},
        values: const <String, String>{},
      );
      expect(html, startsWith('<!doctype html>\n<html lang="en">'));
      expect(html, contains('<meta charset="utf-8">'));
      expect(html, contains('noindex, nofollow'));
      expect(
        html,
        contains(
          '<link rel="canonical" href="https://app.linefm.de/impressum/en/">',
        ),
      );
      expect(html, contains('hreflang="x-default"'));
      expect(html, contains('href="../legal.css"'));
      expect(html, endsWith('</html>\n'));
    });

    test('vollstaendig befuellt: index, mailto, keine Platzhalter', () {
      final Map<String, Object?> meta = jsonDecode(
        File('assets/legal/placeholders.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final Map<String, String> values = <String, String>{
        for (final String k
            in (meta['placeholders']! as Map<String, Object?>).keys)
          k: k == 'BETREIBER_EMAIL' ? 'kontakt@example.org' : 'X',
      };
      final String html = renderPage(
        _doc('de', 'impressum'),
        kind: 'impressum',
        lang: 'de',
        baseUrl: 'https://app.linefm.de',
        providers: <String>{},
        values: values,
      );
      expect(html, contains('index, follow'));
      expect(html, contains('href="mailto:kontakt@example.org"'));
      expect(html, isNot(contains('{{')));
    });

    test('Tags sind ausgewogen', () {
      for (final String kind in <String>['impressum', 'datenschutz']) {
        for (final String lang in <String>['de', 'en']) {
          final String html = renderPage(
            _doc(lang, kind),
            kind: kind,
            lang: lang,
            baseUrl: 'https://app.linefm.de',
            providers: <String>{'umami', 'sentry', 'firebase'},
            values: const <String, String>{},
          );
          for (final String tag in <String>[
            'p',
            'ul',
            'li',
            'a',
            'h2',
            'main',
          ]) {
            final int open = RegExp('<$tag[ >]').allMatches(html).length;
            final int close = '</$tag>'.allMatches(html).length;
            expect(open, close, reason: '$kind/$lang <$tag>');
          }
        }
      }
    });
  });

  group('Eingecheckte Seiten (N01)', () {
    // web/impressum und web/datenschutz liegen im Repo, damit lokale Builds
    // und Plesk-Uploads Rechtstexte haben. Sie muessen dem Generator ohne
    // Werte und ohne Telemetrie entsprechen; sonst liefern sie alten Text.
    // Neu erzeugen: dart run tool/gen_legal_html.dart
    for (final String kind in <String>['impressum', 'datenschutz']) {
      for (final String lang in <String>['de', 'en']) {
        test('$kind/$lang entspricht der Generator-Ausgabe', () {
          final String dir = lang == 'de' ? 'web/$kind' : 'web/$kind/en';
          final String expected = renderPage(
            _doc(lang, kind),
            kind: kind,
            lang: lang,
            baseUrl: 'https://app.linefm.de',
            providers: <String>{},
            values: <String, String>{},
          );
          expect(
            File('$dir/index.html').readAsStringSync(),
            expected,
            reason: 'dart run tool/gen_legal_html.dart ausfuehren',
          );
        });
      }
      test('$kind/legal.css ist aktuell', () {
        expect(File('web/$kind/legal.css').readAsStringSync(), legalCss);
      });
    }
  });

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

  group('Pflicht-Regeln (R3-P01/P02)', () {
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
        open.addAll(openPlaceholders(_doc('de', kind), <String>{}, values));
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
        _doc('de', 'datenschutz'),
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

  group('R4-S01/S02/S03', () {
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
  });
}
