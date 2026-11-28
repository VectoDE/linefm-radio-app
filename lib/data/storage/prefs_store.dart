import 'package:linefm_radio/data/storage/shared_prefs_store.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';

/// Lokale Persistenz mit Einwilligungslogik wie die Web-App (Spec 2.2):
/// ohne Speicher-Bestaetigung wird nichts geschrieben. Implementierung auf
/// Basis shared_preferences: [SharedPrefsStore].
abstract interface class PrefsStore {
  bool get storageConsent;
  Future<void> setStorageConsent({required bool value});

  List<Favorite> readFavorites();
  Future<void> writeFavorites(List<Favorite> favorites);

  /// Favoriten-Sender (Slugs), getrennt von den Song-Favoriten.
  Set<String> readFavoriteStations();
  Future<void> writeFavoriteStations(Set<String> slugs);

  double? readVolume();
  Future<void> writeVolume(double volume);

  AppSettings readSettings();
  Future<void> writeSettings(AppSettings settings);

  String? readLastStation();
  Future<void> writeLastStation(String slug);

  List<AlarmRule> readAlarms();
  Future<void> writeAlarms(List<AlarmRule> alarms);

  /// null = noch nicht entschieden.
  bool? readTelemetryConsent();
  Future<void> writeTelemetryConsent({required bool? value});

  /// Cover-Cache als JSON-Text.
  String? readCoverCache();
  Future<void> writeCoverCache(String json);

  /// Zuletzt gueltig nachgeladene Senderliste samt ETag, als
  /// JSON-Text. Gleiche Regel wie der Cover-Cache: nur mit Bestaetigung.
  String? readStationsCache();
  Future<void> writeStationsCache(String json);

  /// Last known track and history per station as JSON text, so covers and
  /// history show offline after a restart. Same consent rule as above.
  String? readLiveCache();
  Future<void> writeLiveCache(String json);

  /// Speicher loeschen: setzt alles inklusive Bestaetigung zurueck, ausser
  /// "Cover laden: aus" (Datenschutz-Praeferenz).
  Future<void> clearAll();
}

/// Fabrik fuer main(): shared_preferences-Speicher (Web: localStorage).
Future<PrefsStore> createPrefsStore() => SharedPrefsStore.open();
