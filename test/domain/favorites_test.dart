import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/favorites/favorites_logic.dart';
import 'package:linefm_radio/domain/track.dart';

Favorite fav(String slug, String artist, String title, {DateTime? at}) =>
    Favorite(
      key: FavoritesLogic.keyFor(
        stationSlug: slug,
        artist: artist,
        title: title,
      ),
      stationSlug: slug,
      title: title,
      artist: artist,
      savedAt: at,
    );

/// Auszug im Format, das die Web-App in localStorage "linefm-favorites" schreibt.
const String webAppJson = '''
[
  {"key":"linefm:daft punk:one more time","station":"linefm","title":"One More Time","artist":"Daft Punk","artwork":"https://is1-ssl.mzstatic.com/image/600x600bb.jpg","stationLogo":"https://cdn.linefm.de/images/icons/main.png"},
  {"key":"linefmrap:k.i.z.:hurra, die welt geht unter","station":"linefmrap","title":"Hurra, die Welt geht unter","artist":"K.I.Z.","artwork":"https://cdn.linefm.de/images/icons/rap.png","stationLogo":"https://cdn.linefm.de/images/icons/rap.png"}
]
''';

void main() {
  group('Schluessel wie Web-App', () {
    test('Slug, Kuenstler und Titel in Kleinbuchstaben', () {
      expect(
        FavoritesLogic.keyFor(
          stationSlug: 'linefm',
          artist: 'Daft Punk',
          title: 'One More Time',
        ),
        'linefm:daft punk:one more time',
      );
    });

    test(
      'Slug bleibt unveraendert, Doppelpunkte im Titel bleiben erhalten',
      () {
        expect(
          FavoritesLogic.keyFor(
            stationSlug: 'radio3fm',
            artist: 'AC/DC',
            title: 'Rock: The Song',
          ),
          'radio3fm:ac/dc:rock: the song',
        );
      },
    );

    test('fromTrack: Cover-Rueckfall auf Senderlogo, savedAt gesetzt', () {
      final at = DateTime(2026, 11, 18, 12);
      const track = Track(artist: 'A', title: 'B');
      final f = FavoritesLogic.fromTrack(
        stationSlug: 'linefm',
        track: track,
        savedAt: at,
        stationLogoUrl: 'logo',
      );
      expect(f.key, 'linefm:a:b');
      expect(f.artworkUrl, 'logo');
      expect(f.stationLogoUrl, 'logo');
      expect(f.savedAt, at);
      final withCover = FavoritesLogic.fromTrack(
        stationSlug: 'linefm',
        track: track.copyWith(artworkUrl: 'cover'),
        savedAt: at,
        stationLogoUrl: 'logo',
      );
      expect(withCover.artworkUrl, 'cover');
    });
  });

  group('toggle und remove', () {
    test('neue Favoriten kommen nach vorn (unshift)', () {
      final a = fav('linefm', 'A', 'a');
      final b = fav('linefm', 'B', 'b');
      var list = <Favorite>[];
      list = FavoritesLogic.toggle(list, a);
      list = FavoritesLogic.toggle(list, b);
      expect(list.map((f) => f.title), <String>['b', 'a']);
    });

    test('zweites toggle entfernt, Reihenfolge der Rest bleibt', () {
      final a = fav('linefm', 'A', 'a');
      final b = fav('linefm', 'B', 'b');
      final c = fav('linefm', 'C', 'c');
      final list = <Favorite>[c, b, a];
      final result = FavoritesLogic.toggle(list, b);
      expect(result, <Favorite>[c, a]);
      expect(FavoritesLogic.contains(result, b.key), isFalse);
    });

    test('derselbe Titel auf anderem Sender ist ein eigener Favorit', () {
      final a = fav('linefm', 'A', 'a');
      final a2 = fav('linefmrap', 'A', 'a');
      final list = FavoritesLogic.toggle(<Favorite>[a], a2);
      expect(list, hasLength(2));
    });

    test('Gross-/Kleinschreibung aendert den Schluessel nicht', () {
      final a = fav('linefm', 'Daft Punk', 'One More Time');
      final upper = fav('linefm', 'DAFT PUNK', 'ONE MORE TIME');
      expect(FavoritesLogic.toggle(<Favorite>[a], upper), isEmpty);
    });

    test(
      'remove entfernt nur den Schluessel, Eingabeliste bleibt unveraendert',
      () {
        final a = fav('linefm', 'A', 'a');
        final b = fav('linefm', 'B', 'b');
        final list = <Favorite>[a, b];
        expect(FavoritesLogic.remove(list, a.key), <Favorite>[b]);
        expect(list, hasLength(2));
        expect(FavoritesLogic.remove(list, 'gibt-es-nicht'), list);
      },
    );
  });

  group('Speicherformat', () {
    test('encode/decode ist verlustfrei inklusive savedAt', () {
      final list = <Favorite>[
        Favorite(
          key: 'linefm:a:b',
          stationSlug: 'linefm',
          title: 'B',
          artist: 'A',
          artworkUrl: 'https://x/c.jpg',
          stationLogoUrl: 'https://x/l.png',
          savedAt: DateTime.utc(2026, 11, 18, 10, 30),
        ),
        fav('linefmrap', 'C', 'd'),
      ];
      expect(FavoritesLogic.decode(FavoritesLogic.encode(list)), list);
    });

    test(
      'Ausgabe bleibt fuer die Web-App lesbar (station/artwork/stationLogo)',
      () {
        final json = jsonDecode(
          FavoritesLogic.encode(<Favorite>[
            const Favorite(
              key: 'linefm:a:b',
              stationSlug: 'linefm',
              title: 'B',
              artist: 'A',
              artworkUrl: 'cover',
              stationLogoUrl: 'logo',
            ),
          ]),
        ) as List<Object?>;
        final first = json.first! as Map<String, Object?>;
        expect(first['key'], 'linefm:a:b');
        expect(first['station'], 'linefm');
        expect(first['artwork'], 'cover');
        expect(first['stationLogo'], 'logo');
      },
    );
  });

  group('Import aus der Web-App', () {
    test('echtes Web-App-JSON wird gelesen, Reihenfolge bleibt', () {
      final list = FavoritesLogic.decode(webAppJson);
      expect(list, hasLength(2));
      expect(list[0].key, 'linefm:daft punk:one more time');
      expect(list[0].stationSlug, 'linefm');
      expect(list[0].title, 'One More Time');
      expect(list[0].artist, 'Daft Punk');
      expect(list[0].artworkUrl, startsWith('https://is1-ssl.mzstatic.com'));
      expect(
        list[0].stationLogoUrl,
        'https://cdn.linefm.de/images/icons/main.png',
      );
      expect(list[0].savedAt, isNull);
      expect(list[1].key, 'linefmrap:k.i.z.:hurra, die welt geht unter');
      expect(list[1].stationSlug, 'linefmrap');
    });

    test('Key-Schluessel der Web-App passt zur neuen Regel', () {
      for (final f in FavoritesLogic.decode(webAppJson)) {
        expect(
          f.key,
          FavoritesLogic.keyFor(
            stationSlug: f.stationSlug,
            artist: f.artist,
            title: f.title,
          ),
        );
      }
    });

    test('fehlender key wird neu gebildet, Slug aus station', () {
      final list = FavoritesLogic.decode(
        '[{"station":"fobfm","title":"T","artist":"A"}]',
      );
      expect(list.single.key, 'fobfm:a:t');
    });

    test('fehlendes station: Slug aus dem key', () {
      final list = FavoritesLogic.decode(
        '[{"key":"linefm:a:t","title":"T","artist":"A"}]',
      );
      expect(list.single.stationSlug, 'linefm');
    });

    test('leere Cover-Strings werden zu null', () {
      final list = FavoritesLogic.decode(
        '[{"key":"linefm:a:t","station":"linefm","title":"T","artist":"A",'
        '"artwork":"","stationLogo":""}]',
      );
      expect(list.single.artworkUrl, isNull);
      expect(list.single.stationLogoUrl, isNull);
    });

    test('Duplikate: der erste (neueste) bleibt', () {
      final list = FavoritesLogic.decode(
        '[{"key":"linefm:a:t","station":"linefm","title":"Neu","artist":"A"},'
        '{"key":"linefm:a:t","station":"linefm","title":"Alt","artist":"A"}]',
      );
      expect(list, hasLength(1));
      expect(list.single.title, 'Neu');
    });

    test('kaputte Eintraege werden uebersprungen, Rest bleibt', () {
      final list = FavoritesLogic.decode(
        '[42, null, {"title":"ohne Sender","artist":"A"}, {"station":"linefm"},'
        '{"key":"linefm:a:t","station":"linefm","title":"T","artist":"A"}]',
      );
      expect(list.map((f) => f.key), <String>['linefm:a:t']);
    });

    test('kaputtes JSON, null, leer und Nicht-Liste ergeben leere Liste', () {
      expect(FavoritesLogic.decode(null), isEmpty);
      expect(FavoritesLogic.decode(''), isEmpty);
      expect(FavoritesLogic.decode('   '), isEmpty);
      expect(FavoritesLogic.decode('{nicht json'), isEmpty);
      expect(FavoritesLogic.decode('{"a":1}'), isEmpty);
    });
  });

  group('CSV-Export', () {
    test('BOM, Semikolon, CRLF, Kopfzeile', () {
      final csv = FavoritesExport.build(<Favorite>[
        fav(
          'linefm',
          'Daft Punk',
          'One More Time',
          at: DateTime(2026, 11, 18, 9, 5),
        ),
      ], ExportFormat.csv);
      expect(csv.startsWith('﻿'), isTrue);
      final lines = csv.substring(1).split('\r\n');
      expect(lines[0], 'Titel;Künstler;Sender;Gemerkt am');
      expect(lines[1], 'One More Time;Daft Punk;LineFM +MAIN;2026-11-18 09:05');
      expect(lines, hasLength(2));
    });

    test('englische Kopfzeile', () {
      final csv = FavoritesExport.build(
        <Favorite>[],
        ExportFormat.csv,
        labels: FavoritesExportLabels.en,
      );
      expect(csv, '﻿Title;Artist;Station;Saved on');
    });

    test('Escaping: Semikolon, Anfuehrungszeichen, Zeilenumbruch', () {
      final csv = FavoritesExport.build(<Favorite>[
        fav('linefm', 'A; B', 'Say "Hi"\nzweite Zeile'),
      ], ExportFormat.csv);
      final row = csv.substring(1).split('\r\n').skip(1).join('\r\n');
      expect(row, '"Say ""Hi""\nzweite Zeile";"A; B";LineFM +MAIN;');
    });

    test('Formel-Schutz fuer Tabellenkalkulation', () {
      expect(FavoritesExport.escapeCsv('=SUM(A1)'), "'=SUM(A1)");
      expect(FavoritesExport.escapeCsv('+49'), "'+49");
      expect(FavoritesExport.escapeCsv('-1'), "'-1");
      expect(FavoritesExport.escapeCsv('@home'), "'@home");
      expect(FavoritesExport.escapeCsv('normal'), 'normal');
      expect(FavoritesExport.escapeCsv(''), '');
    });

    test('unbekannter Sender-Slug faellt auf den Slug zurueck', () {
      final csv = FavoritesExport.build(<Favorite>[
        fav('unbekannt', 'A', 'T'),
      ], ExportFormat.csv);
      expect(csv, contains('T;A;unbekannt;'));
    });

    test('leere Liste: nur BOM und Kopfzeile', () {
      expect(
        FavoritesExport.build(<Favorite>[], ExportFormat.csv),
        '﻿Titel;Künstler;Sender;Gemerkt am',
      );
    });

    test('Datum ohne savedAt leer, mit Auffuellung', () {
      expect(FavoritesExport.formatDate(null), '');
      expect(
        FavoritesExport.formatDate(DateTime(2026, 1, 2, 3, 4)),
        '2026-01-02 03:04',
      );
    });
  });

  group('Text-Export', () {
    test('eine Zeile je Favorit, ohne BOM', () {
      final text = FavoritesExport.build(<Favorite>[
        fav('linefm', 'Daft Punk', 'One More Time'),
        fav('radio3fm', '', 'Ohne Kuenstler'),
      ], ExportFormat.text);
      expect(
        text,
        'Daft Punk - One More Time (LineFM +MAIN)\nOhne Kuenstler (Radio3FM)',
      );
    });

    test('leere Liste ergibt leeren Text', () {
      expect(FavoritesExport.build(<Favorite>[], ExportFormat.text), '');
    });
  });
}
