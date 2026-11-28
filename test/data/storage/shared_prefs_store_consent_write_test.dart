import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/data/storage/shared_prefs_store.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_prefs_store_helpers.dart';

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
      await s.writeLiveCache('{"v":1}');
      expect((await reopen()).readLiveCache(), '{"v":1}');
      await s.clearAll();
      expect(s.readLiveCache(), isNull);
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
}
