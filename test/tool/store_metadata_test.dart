// Sichert die Store-Metadaten: docs/STORE-TEXTE.md ist die Quelle,
// fastlane/metadata/ ist abgeleitet. Der Test prueft Zeichenlimits von Google
// Play und App Store, Vollstaendigkeit in Deutsch und Englisch und dass beide
// Seiten uebereinstimmen. Die Limits stehen mit Quelle im Kopf von
// tool/store_metadata.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/store_metadata.dart';

void main() {
  final String markdown = File('docs/STORE-TEXTE.md')
      .readAsStringSync()
      .replaceAll('\r\n', '\n');

  group('echtes Repository', () {
    test('Metadaten sind vollstaendig, innerhalb der Limits und aktuell', () {
      expect(checkRepo('.'), isEmpty);
    });

    test('beide Sprachen haben dieselben Dateien', () {
      final Map<String, String> files = parseStoreTexts(markdown);
      Set<String> names(String locale) => files.keys
          .where(
            (String k) => k.contains('/$locale/') || k.startsWith('$locale/'),
          )
          .map((String k) => k.replaceAll(locale, '*'))
          .toSet();
      expect(names('de-DE'), names('en-US'));
      expect(names('de-DE'), isNotEmpty);
    });

    test('Google-Play-Limits: 30, 80, 4000 Zeichen', () {
      final Map<String, String> files = parseStoreTexts(markdown);
      for (final String loc in <String>['de-DE', 'en-US']) {
        expect(
          charCount(files['android/$loc/title.txt']!.trim()),
          lessThanOrEqualTo(30),
        );
        expect(
          charCount(files['android/$loc/short_description.txt']!.trim()),
          lessThanOrEqualTo(80),
        );
        expect(
          charCount(files['android/$loc/full_description.txt']!.trim()),
          lessThanOrEqualTo(4000),
        );
      }
    });

    test(
      'App-Store-Limits: Name und Untertitel 30, Schluesselwoerter 100 Bytes',
      () {
        final Map<String, String> files = parseStoreTexts(markdown);
        for (final String loc in <String>['de-DE', 'en-US']) {
          expect(
            charCount(files['$loc/name.txt']!.trim()),
            lessThanOrEqualTo(30),
          );
          expect(
            charCount(files['$loc/subtitle.txt']!.trim()),
            lessThanOrEqualTo(30),
          );
          expect(
            files['$loc/keywords.txt']!.trim().codeUnits.length,
            lessThanOrEqualTo(100),
          );
        }
      },
    );
  });

  group('Pruefungen greifen', () {
    test('zu langer Titel wird gemeldet', () {
      final Map<String, String> files = parseStoreTexts(markdown);
      files['android/de-DE/title.txt'] = '${'x' * 31}\n';
      expect(
        checkLimits(files),
        contains(contains('android/de-DE/title.txt hat 31 Zeichen')),
      );
    });

    test('Schluesselwoerter zaehlen in Bytes', () {
      final Map<String, String> files = parseStoreTexts(markdown);
      // 51 Umlaute = 102 Bytes, aber nur 51 Zeichen.
      files['de-DE/keywords.txt'] = '${'ä' * 51}\n';
      expect(
        checkLimits(files),
        contains(contains('keywords.txt hat 102 Bytes')),
      );
    });

    test('Abweichung zwischen Quelle und Datei wird gemeldet', () {
      final Map<String, String> expected = parseStoreTexts(markdown);
      final Map<String, String> actual = Map<String, String>.of(expected)
        ..['de-DE/name.txt'] = 'Anderer Name\n'
        ..remove('en-US/subtitle.txt')
        ..['de-DE/zusatz.txt'] = 'x\n';
      final List<String> problems = checkInSync(expected, actual);
      expect(problems, contains(contains('de-DE/name.txt weicht')));
      expect(problems, contains(contains('en-US/subtitle.txt fehlt')));
      expect(problems, contains(contains('de-DE/zusatz.txt ist unbekannt')));
    });

    test('fehlende Sprache in der Quelle wird gemeldet', () {
      final String ohneEnglisch = markdown.replaceFirst(
        '### English\n\n**Title**',
        '### Francais\n\n**Title**',
      );
      expect(() => parseStoreTexts(ohneEnglisch), throwsFormatException);
    });

    test('falsche Zeichenzahl in der Quelle wird gemeldet', () {
      final String falsch = markdown.replaceFirst(
        '(12 von 30 Zeichen)',
        '(13 von 30 Zeichen)',
      );
      final List<String> problems = checkStatedCounts(
        falsch,
        parseStoreTexts(falsch),
      );
      expect(problems, contains(contains('nennt 13 Zeichen, gezaehlt 12')));
    });

    test('Platzhalter und Nicht-https-Adressen werden gemeldet', () {
      final Map<String, String> files = parseStoreTexts(markdown);
      files['de-DE/privacy_url.txt'] = 'http://example.org/x\n';
      files['en-US/name.txt'] = '{{NAME}}\n';
      final List<String> problems = checkLimits(files);
      expect(problems, contains(contains('privacy_url.txt ist keine https')));
      expect(
        problems,
        contains(contains('en-US/name.txt enthaelt einen offenen Platzhalter')),
      );
    });
  });
}
