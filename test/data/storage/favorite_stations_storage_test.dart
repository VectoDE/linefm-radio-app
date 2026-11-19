import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/data/storage/shared_prefs_store.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPrefsStore> _open([Map<String, Object> initial = const {}]) {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPrefsStore.open();
}

void main() {
  group('Favoriten-Sender im Speicher (Speicher-Hinweis-Regel)', () {
    test('ohne Bestaetigung wird nichts geschrieben', () async {
      final s = await _open();
      await s.writeFavoriteStations(<String>{'linefm'});
      expect(s.readFavoriteStations(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get(PrefsKeys.favoriteStations), isNull);
    });

    test('mit Bestaetigung gespeichert und nach Neustart gelesen', () async {
      final s = await _open();
      await s.setStorageConsent(value: true);
      await s.writeFavoriteStations(<String>{'fobfm', 'linefmrap'});
      final reopened = await SharedPrefsStore.open();
      expect(reopened.readFavoriteStations(), <String>{'linefmrap', 'fobfm'});
    });

    test('eigener Schluessel, Song-Favoriten bleiben unberuehrt', () async {
      final s = await _open();
      await s.setStorageConsent(value: true);
      final song = Favorite(
        key: 'linefm:a:t',
        stationSlug: 'linefm',
        title: 't',
        artist: 'a',
        savedAt: DateTime.utc(2026, 11, 19),
      );
      await s.writeFavorites(<Favorite>[song]);
      await s.writeFavoriteStations(<String>{'linefm'});
      expect(PrefsKeys.favoriteStations, isNot(PrefsKeys.favorites));
      expect(s.readFavorites().single.key, 'linefm:a:t');
      await s.writeFavoriteStations(const <String>{});
      expect(s.readFavorites(), hasLength(1));
      expect(s.readFavoriteStations(), isEmpty);
    });

    test(
      'Speicher loeschen und Widerruf entfernen die Favoriten-Sender',
      () async {
        final s = await _open();
        await s.setStorageConsent(value: true);
        await s.writeFavoriteStations(<String>{'linefm'});
        await s.clearAll();
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.get(PrefsKeys.favoriteStations), isNull);
        await s.setStorageConsent(value: true);
        expect(s.readFavoriteStations(), isEmpty);
        expect(PrefsKeys.data, contains(PrefsKeys.favoriteStations));
      },
    );

    test('Start ohne Bestaetigung raeumt Altdaten weg', () async {
      final s = await _open(<String, Object>{
        PrefsKeys.favoriteStations: '["linefm"]',
      });
      expect(s.readFavoriteStations(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get(PrefsKeys.favoriteStations), isNull);
    });

    test('InMemoryPrefsStore verhaelt sich gleich bei clearAll', () async {
      final s = InMemoryPrefsStore();
      await s.writeFavoriteStations(<String>{'linefm'});
      expect(s.readFavoriteStations(), <String>{'linefm'});
      await s.clearAll();
      expect(s.readFavoriteStations(), isEmpty);
    });
  });
}
