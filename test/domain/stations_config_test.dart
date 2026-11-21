import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/stations_config.dart';

/// Pruefung der Senderliste (Issue #91): echte Datei, Hinzufuegen,
/// Entfernen, Umsortieren und typische Tippfehler.
void main() {
  Map<String, Object?> sender(String slug, {Map<String, Object?>? extra}) =>
      <String, Object?>{
        'kuerzel': slug,
        'name': 'Sender $slug',
        'farbe': '#112233',
        'logo': 'https://cdn.linefm.de/images/icons/$slug.png',
        ...?extra,
      };

  String file(List<Map<String, Object?>> list, {Object? version = 1}) =>
      const JsonEncoder.withIndent(
        '  ',
      ).convert(<String, Object?>{'schemaVersion': ?version, 'sender': list});

  StationsConfigResult parse(String text) => parseStationsConfig(text);

  List<String> slugs(StationsConfigResult r) => <String>[
    for (final e in r.active) e.slug,
  ];

  group('echte Dateien', () {
    test('assets/config/stations.json ist gueltig', () {
      final r = parseStationsConfigBytes(
        File('assets/config/stations.json').readAsBytesSync(),
      );
      expect(r.errors, isEmpty);
      expect(r.active, isNotEmpty);
      for (final e in r.entries) {
        if (e.logoAsset != null) {
          expect(File(e.logoAsset!).existsSync(), isTrue, reason: e.logoAsset);
        }
      }
    });

    test('Test-Fassung enthaelt die sechs Sender', () {
      final r = parse(
        File('test/fixtures/stations/stations_6.json').readAsStringSync(),
      );
      expect(r.ok, isTrue);
      expect(slugs(r), <String>[
        'linefm',
        'linefmrap',
        'linefmgaming',
        'linefmlofi',
        'radio3fm',
        'fobfm',
      ]);
    });
  });

  group('Pflege der Liste', () {
    final base = <Map<String, Object?>>[sender('a'), sender('b'), sender('c')];

    test('Hinzufuegen haengt den Sender an', () {
      final r = parse(file(<Map<String, Object?>>[...base, sender('neu')]));
      expect(r.ok, isTrue);
      expect(slugs(r), <String>['a', 'b', 'c', 'neu']);
      expect(r.active.last.logoAsset, isNull);
    });

    test('Entfernen nimmt den Sender heraus', () {
      final r = parse(file(<Map<String, Object?>>[base[0], base[2]]));
      expect(slugs(r), <String>['a', 'c']);
    });

    test('Umsortieren uebernimmt die Dateireihenfolge', () {
      final r = parse(file(<Map<String, Object?>>[base[2], base[0], base[1]]));
      expect(slugs(r), <String>['c', 'a', 'b']);
    });

    test('ausgeblendete Sender stehen nicht in der Anzeige', () {
      final r = parse(
        file(<Map<String, Object?>>[
          base[0],
          sender('b', extra: <String, Object?>{'aktiv': false}),
        ]),
      );
      expect(r.ok, isTrue);
      expect(r.entries.length, 2);
      expect(slugs(r), <String>['a']);
    });

    test('Farbe wird als undurchsichtiger ARGB-Wert gelesen', () {
      final r = parse(file(<Map<String, Object?>>[sender('a')]));
      expect(r.active.single.color, 0xFF112233);
    });
  });

  group('Fehler werden verstaendlich gemeldet', () {
    void expectError(String text) {
      final r = parse(text);
      expect(r.ok, isFalse);
      expect(r.errors, isNotEmpty);
    }

    test('kaputtes JSON nennt die Zeile', () {
      final r = parse(
        '{\n  "schemaVersion": 1,\n  "sender": [\n    {,\n  ]\n}',
      );
      expect(r.ok, isFalse);
      expect(r.errors.first.line, isNotNull);
    });

    test('fehlende oder falsche schemaVersion', () {
      expectError(file(<Map<String, Object?>>[sender('a')], version: null));
      expectError(file(<Map<String, Object?>>[sender('a')], version: 2));
    });

    test('leere Liste und nur ausgeblendete Sender', () {
      expectError(file(<Map<String, Object?>>[]));
      expectError(
        file(<Map<String, Object?>>[
          sender('a', extra: <String, Object?>{'aktiv': false}),
        ]),
      );
    });

    test('ungueltiges oder doppeltes Kuerzel', () {
      expectError(file(<Map<String, Object?>>[sender('Gross')]));
      expectError(file(<Map<String, Object?>>[sender('a/../b')]));
      expectError(file(<Map<String, Object?>>[sender('a'), sender('a')]));
    });

    test('Farbe im falschen Format', () {
      expectError(
        file(<Map<String, Object?>>[
          sender('a', extra: <String, Object?>{'farbe': 'rot'}),
        ]),
      );
    });

    test('Logo nur per https von erlaubten Hosts', () {
      for (final url in <String>[
        'http://cdn.linefm.de/x.png',
        'https://evil.example/x.png',
        'https://user@cdn.linefm.de/x.png',
        'https://cdn.linefm.de.evil.example/x.png',
        'javascript:alert(1)',
      ]) {
        final r = parse(
          file(<Map<String, Object?>>[
            sender('a', extra: <String, Object?>{'logo': url}),
          ]),
        );
        expect(r.ok, isFalse, reason: url);
      }
      expect(logoUrlProblem('https://assets.laut.fm/x.png'), isNull);
    });

    test('logoDatei nur unter assets/images/stations/', () {
      expectError(
        file(<Map<String, Object?>>[
          sender(
            'a',
            extra: <String, Object?>{'logoDatei': '../../etc/passwd'},
          ),
        ]),
      );
    });

    test('Steuerzeichen werden entfernt, leere Namen gemeldet', () {
      final r = parse(
        file(<Map<String, Object?>>[
          sender('a', extra: <String, Object?>{'name': 'A\u202Eb\u0007c'}),
        ]),
      );
      expect(r.ok, isTrue);
      expect(r.active.single.name, 'A b c');
      expectError(
        file(<Map<String, Object?>>[
          sender('a', extra: <String, Object?>{'name': '  '}),
        ]),
      );
    });

    test('unbekanntes Feld (Tippfehler) wird gemeldet', () {
      final r = parse(
        file(<Map<String, Object?>>[
          sender('a', extra: <String, Object?>{'nmae': 'x'}),
        ]),
      );
      expect(r.ok, isFalse);
      expect(r.errors.join(' '), contains('Meintest du "name"?'));
      expectError(
        file(<Map<String, Object?>>[sender('a')])
            .replaceFirst('"schemaVersion"', '"streams": [], "schemaVersion"'),
      );
    });

    test('Datei ueber dem Groessenlimit', () {
      final big = List<int>.filled(stationsConfigMaxBytes + 1, 0x20);
      expect(parseStationsConfigBytes(big).ok, isFalse);
    });

    test('kein UTF-8', () {
      expect(parseStationsConfigBytes(<int>[0xFF, 0xFE, 0x00]).ok, isFalse);
    });

    test('zu viele Sender', () {
      expectError(
        file(<Map<String, Object?>>[
          for (var i = 0; i <= stationsConfigMaxStations; i++) sender('s$i'),
        ]),
      );
    });
  });

  test('nachgeladene Fassung: unbekannte logoDatei faellt weg', () {
    final r = parseStationsConfig(
      file(<Map<String, Object?>>[
        sender(
          'a',
          extra: <String, Object?>{
            'logoDatei': 'assets/images/stations/neu.png',
          },
        ),
      ]),
      knownLogoAssets: const <String>{},
    );
    expect(r.ok, isTrue);
    expect(r.active.single.logoAsset, isNull);
  });
}
