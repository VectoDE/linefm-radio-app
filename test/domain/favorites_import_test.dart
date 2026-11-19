import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/favorites/favorites_import.dart';
import 'package:linefm_radio/domain/favorites/favorites_logic.dart';

Favorite _fav(
  String slug,
  String artist,
  String title, {
  DateTime? savedAt,
  String? artwork,
}) => Favorite(
  key: FavoritesLogic.keyFor(stationSlug: slug, artist: artist, title: title),
  stationSlug: slug,
  title: title,
  artist: artist,
  artworkUrl: artwork,
  savedAt: savedAt,
);

void main() {
  final saved = DateTime(2026, 11, 18, 21, 5);
  final list = <Favorite>[
    _fav('linefm', 'Artist; A', 'Song "One"', savedAt: saved),
    _fav('linefmrap', '', '=SUM(A1)', savedAt: saved),
    _fav('fobfm', 'Band', 'Live - Remix'),
  ];

  group('Rundreise Export -> Import', () {
    for (final labels in <FavoritesExportLabels>[
      FavoritesExportLabels.de,
      FavoritesExportLabels.en,
    ]) {
      test('CSV (${labels.title})', () {
        final csv = FavoritesExport.build(
          list,
          ExportFormat.csv,
          labels: labels,
        );
        final result = FavoritesImport.parse(csv);
        expect(result.skipped, 0);
        expect(result.favorites.map((f) => f.key), list.map((f) => f.key));
        expect(result.favorites[0].artist, 'Artist; A');
        expect(result.favorites[0].title, 'Song "One"');
        expect(result.favorites[0].savedAt, saved);
        expect(result.favorites[1].title, '=SUM(A1)', reason: 'Formelschutz');
        expect(result.favorites[2].savedAt, isNull);
        expect(result.favorites[2].stationLogoUrl, isNotNull);
      });
    }

    test('Textliste', () {
      final text = FavoritesExport.build(list, ExportFormat.text);
      final result = FavoritesImport.parse(text);
      expect(result.skipped, 0);
      expect(result.favorites.map((f) => f.key), list.map((f) => f.key));
      expect(result.favorites[2].artist, 'Band');
      expect(result.favorites[2].title, 'Live - Remix');
    });

    test('Zeilenumbruch in einem CSV-Feld', () {
      final csv = FavoritesExport.build(<Favorite>[
        _fav('linefm', 'A', 'Zeile 1\nZeile 2'),
      ], ExportFormat.csv);
      final result = FavoritesImport.parse(csv);
      expect(result.favorites.single.title, 'Zeile 1\nZeile 2');
    });
  });

  group('robust', () {
    test('unbekannter Sender und leerer Titel werden uebersprungen', () {
      const csv =
          'Titel;Künstler;Sender;Gemerkt am\r\n'
          'Song;A;Unbekannt FM;\r\n'
          ';A;LineFM +MAIN;\r\n'
          'Gut;B;linefmlofi;2026-02-30 10:00\r\n';
      final result = FavoritesImport.parse(csv);
      expect(result.skipped, 2);
      expect(result.favorites.single.stationSlug, 'linefmlofi');
      expect(result.favorites.single.savedAt, isNull, reason: '30. Februar');
    });

    test('Doppelte in der Datei zaehlen einmal', () {
      const text = 'A - Song (LineFM +RAP)\na - SONG (LineFM +RAP)\n';
      final result = FavoritesImport.parse(text);
      expect(result.favorites, hasLength(1));
    });

    test('fremde Datei: FormatException', () {
      expect(
        () => FavoritesImport.parse('hallo welt\nnoch eine zeile'),
        throwsFormatException,
      );
      expect(() => FavoritesImport.parse('   '), throwsFormatException);
    });
  });

  group('merge', () {
    test('vorhandene vorn, neue dahinter, Doppelte einmal', () {
      final existing = <Favorite>[
        _fav('linefm', 'Artist; A', 'Song "One"', artwork: 'https://c/x.jpg'),
      ];
      final merged = FavoritesImport.merge(existing, list);
      expect(merged.added, 2);
      expect(merged.favorites, hasLength(3));
      expect(merged.favorites.first.artworkUrl, 'https://c/x.jpg');
      expect(merged.favorites.first.savedAt, saved, reason: 'Datum ergaenzt');
    });

    test('nichts Neues: added 0', () {
      final merged = FavoritesImport.merge(list, list);
      expect(merged.added, 0);
      expect(merged.favorites, hasLength(3));
    });
  });
}
