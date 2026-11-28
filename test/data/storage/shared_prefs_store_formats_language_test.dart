import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/data/storage/shared_prefs_store.dart';
import 'package:linefm_radio/data/storage/webapp_migration.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/in_memory_prefs_store.dart';
import 'shared_prefs_store_helpers.dart';

void main() {
  group('Daten im Format der Web-App (z. B. gleiche Origin)', () {
    test('Schluessel und Textwerte der Web-App werden gelesen', () async {
      final s = await open(webAppValues);
      expect(s.storageConsent, isTrue);
      final favorites = s.readFavorites();
      expect(favorites, hasLength(1));
      expect(favorites.single.key, 'linefm:daft punk:one more time');
      expect(favorites.single.artworkUrl, 'https://x/c.jpg');
      expect(
        favorites.single.stationLogoUrl,
        'https://cdn.linefm.de/images/icons/main.png',
      );
      expect(s.readVolume(), 0.4);
      expect(s.readSettings().marquee, isFalse);
      expect(s.readSettings().rememberVolume, isTrue);
      expect(s.readSettings().autoplay, isTrue);
      expect(s.readLastStation(), 'linefmrap');
    });

    test('Web-App-Daten ohne Bestaetigung werden verworfen', () async {
      final s = await open(<String, Object>{
        ...webAppValues,
        'linefm-storage-notice-dismissed': 'false',
      });
      expect(s.storageConsent, isFalse);
      expect(s.readFavorites(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('linefm-favorites'), isFalse);
    });

    test('migrateWebappData ist ein No-Op (Begruendung im Code)', () async {
      final s = await open(webAppValues);
      final before = (await SharedPreferences.getInstance()).getKeys();
      await migrateWebappData(s);
      expect((await SharedPreferences.getInstance()).getKeys(), before);
    });
  });

  group('InMemoryPrefsStore (Fake) und Fabrik', () {
    test('Fake verhaelt sich als Speicher', () async {
      final s = InMemoryPrefsStore();
      await s.setStorageConsent(value: true);
      await s.writeFavorites(<Favorite>[fav('T')]);
      await s.writeVolume(0.5);
      await s.writeSettings(const AppSettings(autoplay: false));
      await s.writeLastStation('linefm');
      await s.writeAlarms(<AlarmRule>[
        const AlarmRule(id: 'a', hour: 7, minute: 0, stationSlug: 'linefm'),
      ]);
      await s.writeTelemetryConsent(value: true);
      await s.writeCoverCache('{}');
      expect(s.readFavorites(), hasLength(1));
      expect(s.readVolume(), 0.5);
      expect(s.readSettings().autoplay, isFalse);
      expect(s.readLastStation(), 'linefm');
      expect(s.readAlarms(), hasLength(1));
      expect(s.readTelemetryConsent(), isTrue);
      expect(s.readCoverCache(), '{}');
      await s.clearAll();
      expect(s.storageConsent, isFalse);
      expect(s.readFavorites(), isEmpty);
      expect(s.readAlarms(), isEmpty);
      expect(s.readTelemetryConsent(), isNull);
    });

    test('createPrefsStore liefert den shared_preferences-Speicher', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      expect(await createPrefsStore(), isA<SharedPrefsStore>());
    });
  });

  group('Cover aus ohne Speicher-Bestaetigung', () {
    test('wird gemerkt und gilt nach Neustart', () async {
      final store = await open();
      expect(store.storageConsent, isFalse);
      await store.writeSettings(const AppSettings(loadArtwork: false));
      expect(store.readSettings().loadArtwork, isFalse);

      final again = await reopen();
      expect(again.readSettings().loadArtwork, isFalse);
      // Andere Einstellungen bleiben ohne Bestaetigung beim Standard.
      expect(again.readSettings().marquee, const AppSettings().marquee);
    });

    test(
      '"an" entfernt den Eintrag, Speicher loeschen behaelt "aus"',
      () async {
        final store = await open();
        await store.writeSettings(const AppSettings(loadArtwork: false));
        await store.writeSettings(const AppSettings());
        expect(
          (await SharedPreferences.getInstance()).containsKey(
            PrefsKeys.loadArtwork,
          ),
          isFalse,
        );

        await store.writeSettings(const AppSettings(loadArtwork: false));
        await store.clearAll();
        expect((await reopen()).readSettings().loadArtwork, isFalse);
      },
    );

    test('Speicher loeschen behaelt nur "Cover aus"', () async {
      final s = await openConsented();
      await s.writeFavorites(<Favorite>[fav('T')]);
      await s.writeSettings(
        const AppSettings(loadArtwork: false, marquee: false),
      );
      await s.writeLastStation('fobfm');
      await s.clearAll();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), <String>{PrefsKeys.loadArtwork});
      final again = await reopen();
      expect(again.storageConsent, isFalse);
      expect(again.readFavorites(), isEmpty);
      expect(again.readLastStation(), isNull);
      expect(again.readSettings(), const AppSettings(loadArtwork: false));
    });

    test('InMemoryPrefsStore behaelt "Cover aus" beim Loeschen', () async {
      final m = InMemoryPrefsStore();
      await m.setStorageConsent(value: true);
      await m.writeSettings(
        const AppSettings(loadArtwork: false, marquee: false),
      );
      await m.clearAll();
      expect(m.readSettings(), const AppSettings(loadArtwork: false));
    });

    test('Widerruf der Bestaetigung behaelt "aus"', () async {
      final store = await openConsented();
      await store.writeSettings(
        const AppSettings(loadArtwork: false, marquee: false),
      );
      await store.setStorageConsent(value: false);
      final settings = (await reopen()).readSettings();
      expect(settings.loadArtwork, isFalse);
      expect(settings.marquee, const AppSettings().marquee);
    });
  });

  group('Sprachwahl ohne Speicher-Bestaetigung', () {
    test('wird sofort gespeichert und gilt nach Neustart', () async {
      final store = await open();
      expect(store.storageConsent, isFalse);
      await store.writeSettings(const AppSettings(language: AppLanguage.en));
      expect(store.readSettings().language, AppLanguage.en);

      final again = await reopen();
      expect(again.storageConsent, isFalse);
      expect(again.readSettings().language, AppLanguage.en);
    });

    test('alle anderen Einstellungen bleiben beim Standard', () async {
      final store = await open();
      await store.writeSettings(
        const AppSettings(language: AppLanguage.de, marquee: false),
      );
      final settings = (await reopen()).readSettings();
      expect(settings.language, AppLanguage.de);
      expect(settings.marquee, const AppSettings().marquee);
      expect((await SharedPreferences.getInstance()).getKeys(), <String>{
        PrefsKeys.language,
      });
    });

    test('Systemsprache entfernt den Eintrag', () async {
      final store = await open();
      await store.writeSettings(const AppSettings(language: AppLanguage.en));
      await store.writeSettings(const AppSettings());
      expect(
        (await SharedPreferences.getInstance()).containsKey(PrefsKeys.language),
        isFalse,
      );
    });

    test('Speicher loeschen setzt die Sprache zurueck', () async {
      final store = await openConsented();
      await store.writeSettings(const AppSettings(language: AppLanguage.en));
      await store.clearAll();
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
      expect((await reopen()).readSettings().language, AppLanguage.system);
    });

    test('Widerruf der Bestaetigung behaelt die Sprache', () async {
      final store = await openConsented();
      await store.writeSettings(const AppSettings(language: AppLanguage.en));
      await store.setStorageConsent(value: false);
      expect((await reopen()).readSettings().language, AppLanguage.en);
    });

    test('mit Bestaetigung bleibt die Wahl wie bisher erhalten', () async {
      final store = await openConsented();
      await store.writeSettings(const AppSettings(language: AppLanguage.de));
      expect((await reopen()).readSettings().language, AppLanguage.de);
    });
  });
}
