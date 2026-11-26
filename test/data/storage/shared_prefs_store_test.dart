import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/data/storage/shared_prefs_store.dart';
import 'package:linefm_radio/data/storage/webapp_migration.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Echter Auszug der Web-App (Schluessel und Werte wie von localStorage).
const Map<String, Object> webAppValues = <String, Object>{
  'linefm-favorites':
      '[{"key":"linefm:daft punk:one more time","station":"linefm",'
      '"title":"One More Time","artist":"Daft Punk","artwork":"https://x/c.jpg",'
      '"stationLogo":"https://cdn.linefm.de/images/icons/main.png"}]',
  'linefm-volume': '0.4',
  'linefm-storage-notice-dismissed': 'true',
  'linefm-setting-marquee': 'false',
  'linefm-setting-remember-volume': 'true',
  'linefm-last-station': 'linefmrap',
};

Future<SharedPrefsStore> open([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPrefsStore.open();
}

Future<SharedPrefsStore> openConsented() async {
  final store = await open();
  await store.setStorageConsent(value: true);
  return store;
}

/// Neu oeffnen mit denselben (gemockten) Daten, simuliert App-Neustart.
Future<SharedPrefsStore> reopen() => SharedPrefsStore.open();

Favorite fav(String title) => Favorite(
  key: 'linefm:a:${title.toLowerCase()}',
  stationSlug: 'linefm',
  title: title,
  artist: 'A',
  savedAt: DateTime.utc(2026, 11, 18, 12),
);

void main() {
  group('ohne Speicher-Bestaetigung wird nichts geschrieben', () {
    test('Standardwerte beim Lesen', () async {
      final s = await open();
      expect(s.storageConsent, isFalse);
      expect(s.readFavorites(), isEmpty);
      expect(s.readVolume(), isNull);
      expect(s.readSettings(), const AppSettings());
      expect(s.readLastStation(), isNull);
      expect(s.readAlarms(), isEmpty);
      expect(s.readTelemetryConsent(), isNull);
      expect(s.readCoverCache(), isNull);
    });

    test('alle write*-Aufrufe sind wirkungslos, auch nach Neustart', () async {
      final s = await open();
      await s.writeFavorites(<Favorite>[fav('T')]);
      await s.writeVolume(0.5);
      await s.writeSettings(const AppSettings(marquee: false));
      await s.writeLastStation('linefm');
      await s.writeAlarms(<AlarmRule>[
        const AlarmRule(id: 'a', hour: 7, minute: 0, stationSlug: 'linefm'),
      ]);
      await s.writeTelemetryConsent(value: true);
      await s.writeCoverCache('{}');
      expect(s.readFavorites(), isEmpty);
      expect(s.readSettings(), const AppSettings());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
      final again = await reopen();
      expect(again.readFavorites(), isEmpty);
      expect(again.readLastStation(), isNull);
    });

    test(
      'Altdaten ohne Bestaetigung werden beim Start entfernt (wie Web-App)',
      () async {
        final s = await open(<String, Object>{
          'linefm-favorites': '[]',
          'linefm-volume': '0.3',
          'linefm-setting-marquee': 'false',
          'linefm-last-station': 'fobfm',
          'unrelated-key': 'bleibt',
        });
        expect(s.storageConsent, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys(), <String>{'unrelated-key'});
      },
    );
  });

  group('nach Bestaetigung', () {
    test('Bestaetigung bleibt ueber Neustart erhalten', () async {
      final s = await openConsented();
      expect(s.storageConsent, isTrue);
      expect((await reopen()).storageConsent, isTrue);
    });

    test('Favoriten: Rundlauf mit Reihenfolge', () async {
      final s = await openConsented();
      final list = <Favorite>[fav('Neu'), fav('Alt')];
      await s.writeFavorites(list);
      expect(s.readFavorites(), list);
      expect((await reopen()).readFavorites(), list);
    });

    test('Favoriten: kaputter Speicher ergibt leere Liste', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'linefm-storage-notice-dismissed': true,
        'linefm-favorites': '{kaputt',
      });
      final s = await SharedPrefsStore.open();
      expect(s.readFavorites(), isEmpty);
    });

    test('Lautstaerke: Rundlauf, Begrenzung 0..1', () async {
      final s = await openConsented();
      await s.writeVolume(0.7);
      expect(s.readVolume(), 0.7);
      await s.writeVolume(3);
      expect(s.readVolume(), 1.0);
      await s.writeVolume(-1);
      expect(s.readVolume(), 0.0);
      await s.writeVolume(double.nan);
      expect(s.readVolume(), 0.0);
    });

    test(
      'Lautstaerke wird nur gemerkt, wenn "Lautstaerke merken" an ist',
      () async {
        final s = await openConsented();
        await s.writeVolume(0.4);
        await s.writeSettings(const AppSettings(rememberVolume: false));
        expect(s.readVolume(), isNull);
        await s.writeVolume(0.9);
        await s.writeSettings(const AppSettings());
        expect(s.readVolume(), 0.4);
      },
    );

    test('Einstellungen: Rundlauf aller Felder', () async {
      final s = await openConsented();
      const settings = AppSettings(
        marquee: false,
        rememberVolume: false,
        autoplay: false,
        closeToTray: false,
        themeMode: AppThemeMode.dark,
        language: AppLanguage.en,
        coverCacheLimit: CoverCacheLimit.mb100,
      );
      await s.writeSettings(settings);
      expect(s.readSettings(), settings);
      expect((await reopen()).readSettings(), settings);
    });

    test('letzte Station', () async {
      final s = await openConsented();
      await s.writeLastStation('radio3fm');
      expect(s.readLastStation(), 'radio3fm');
      expect((await reopen()).readLastStation(), 'radio3fm');
    });

    test('Wecker: Rundlauf, kaputte Eintraege werden uebersprungen', () async {
      final s = await openConsented();
      final alarms = <AlarmRule>[
        const AlarmRule(
          id: 'a',
          hour: 6,
          minute: 45,
          stationSlug: 'linefmlofi',
          weekdays: <int>{1, 2, 3, 4, 5},
          volume: 0.8,
        ),
        const AlarmRule(
          id: 'b',
          hour: 22,
          minute: 0,
          stationSlug: 'linefm',
          enabled: false,
        ),
      ];
      await s.writeAlarms(alarms);
      expect(s.readAlarms(), alarms);
      expect((await reopen()).readAlarms(), alarms);

      SharedPreferences.setMockInitialValues(<String, Object>{
        'linefm-storage-notice-dismissed': true,
        'linefm-alarms':
            '[1,{"id":"a","hour":99,"minute":0,"stationSlug":"x"},'
            '{"id":"ok","hour":7,"minute":5,"stationSlug":"linefm"}]',
      });
      final broken = await SharedPrefsStore.open();
      expect(broken.readAlarms().map((a) => a.id), <String>['ok']);
      SharedPreferences.setMockInitialValues(<String, Object>{
        'linefm-storage-notice-dismissed': true,
        'linefm-alarms': 'kein json',
      });
      expect((await SharedPrefsStore.open()).readAlarms(), isEmpty);
      SharedPreferences.setMockInitialValues(<String, Object>{
        'linefm-storage-notice-dismissed': true,
        'linefm-alarms': '{"a":1}',
      });
      expect((await SharedPrefsStore.open()).readAlarms(), isEmpty);
    });

    test('Telemetrie-Einwilligung: ja, nein, undefiniert', () async {
      final s = await openConsented();
      expect(s.readTelemetryConsent(), isNull);
      await s.writeTelemetryConsent(value: true);
      expect(s.readTelemetryConsent(), isTrue);
      await s.writeTelemetryConsent(value: false);
      expect(s.readTelemetryConsent(), isFalse);
      expect((await reopen()).readTelemetryConsent(), isFalse);
      await s.writeTelemetryConsent(value: null);
      expect(s.readTelemetryConsent(), isNull);
    });

    test('Cover-Cache', () async {
      final s = await openConsented();
      await s.writeCoverCache('{"a":"b"}');
      expect(s.readCoverCache(), '{"a":"b"}');
      expect((await reopen()).readCoverCache(), '{"a":"b"}');
    });
  });

  group('Speicher loeschen', () {
    test('clearAll setzt alles inklusive Bestaetigung zurueck', () async {
      final s = await openConsented();
      await s.writeFavorites(<Favorite>[fav('T')]);
      await s.writeVolume(0.5);
      await s.writeSettings(const AppSettings(marquee: false));
      await s.writeLastStation('fobfm');
      await s.writeTelemetryConsent(value: true);
      await s.writeCoverCache('{}');
      await s.clearAll();
      expect(s.storageConsent, isFalse);
      expect(s.readFavorites(), isEmpty);
      expect(s.readVolume(), isNull);
      expect(s.readSettings(), const AppSettings());
      expect(s.readLastStation(), isNull);
      expect(s.readTelemetryConsent(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
      await s.writeFavorites(<Favorite>[fav('Nach dem Loeschen')]);
      expect(prefs.getKeys(), isEmpty);
      expect((await reopen()).storageConsent, isFalse);
    });

    test('Bestaetigung widerrufen loescht die Daten', () async {
      final s = await openConsented();
      await s.writeLastStation('fobfm');
      await s.setStorageConsent(value: false);
      expect(s.storageConsent, isFalse);
      expect(s.readLastStation(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('nach clearAll kann erneut bestaetigt werden', () async {
      final s = await openConsented();
      await s.clearAll();
      await s.setStorageConsent(value: true);
      await s.writeLastStation('linefm');
      expect((await reopen()).readLastStation(), 'linefm');
    });
  });

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

  group('Cover aus ohne Speicher-Bestaetigung (N4)', () {
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

    test('Speicher loeschen behaelt nur "Cover aus" (R3-P03)', () async {
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
}
