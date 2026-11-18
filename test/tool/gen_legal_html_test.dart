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
}
