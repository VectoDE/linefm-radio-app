import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/data/storage/shared_prefs_store.dart';
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
