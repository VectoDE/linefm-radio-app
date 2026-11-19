import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/favorites/favorite_stations_logic.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';

void main() {
  final main = stationBySlug('linefm')!;
  final lofi = stationBySlug('linefmlofi')!;
  final fob = stationBySlug('fobfm')!;

  group('FavoriteStationsLogic', () {
    test('toggle merkt und entfernt', () {
      var slugs = const <String>{};
      slugs = FavoriteStationsLogic.toggle(slugs, lofi);
      expect(slugs, <String>{'linefmlofi'});
      expect(FavoriteStationsLogic.contains(slugs, lofi), isTrue);
      slugs = FavoriteStationsLogic.toggle(slugs, main);
      expect(slugs, <String>{'linefmlofi', 'linefm'});
      slugs = FavoriteStationsLogic.toggle(slugs, lofi);
      expect(slugs, <String>{'linefm'});
      expect(FavoriteStationsLogic.contains(slugs, lofi), isFalse);
    });

    test('toggle aendert die Eingabe nicht', () {
      final before = <String>{'linefm'};
      FavoriteStationsLogic.toggle(before, fob);
      expect(before, <String>{'linefm'});
    });

    test('Sender in Reihenfolge der Senderliste, egal wie gemerkt', () {
      final slugs = <String>{'fobfm', 'linefmlofi', 'linefm'};
      expect(FavoriteStationsLogic.stations(slugs), <Object>[main, lofi, fob]);
    });

    test('unbekannte Slugs fallen weg', () {
      expect(
        FavoriteStationsLogic.stations(<String>{'gibtsnicht', 'fobfm'}),
        <Object>[fob],
      );
    });

    test('encode/decode: Roundtrip in Senderlisten-Reihenfolge', () {
      final json = FavoriteStationsLogic.encode(<String>{'fobfm', 'linefm'});
      expect(json, '["linefm","fobfm"]');
      expect(FavoriteStationsLogic.decode(json), <String>{'linefm', 'fobfm'});
    });

    test('decode ist tolerant', () {
      expect(FavoriteStationsLogic.decode(null), isEmpty);
      expect(FavoriteStationsLogic.decode(''), isEmpty);
      expect(FavoriteStationsLogic.decode('{kaputt'), isEmpty);
      expect(FavoriteStationsLogic.decode('{"a":1}'), isEmpty);
      expect(
        FavoriteStationsLogic.decode('["linefm", 3, null, "weg", "linefm"]'),
        <String>{'linefm'},
      );
    });

    test(
      'getrennt von Song-Favoriten: eigener Datentyp ohne Songschluessel',
      () {
        // Song-Favoriten haben die Form station:artist:title, Sender-Favoriten
        // sind reine Slugs. Ein Song-Schluessel wird nicht als Sender gelesen.
        expect(
          FavoriteStationsLogic.decode('["linefm:daft punk:one more time"]'),
          isEmpty,
        );
      },
    );
  });
}
