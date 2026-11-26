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
  /// "Cover laden: aus" (Datenschutz-Praeferenz, R3-P03).
  Future<void> clearAll();
}

/// Fabrik fuer main(): shared_preferences-Speicher (Web: localStorage).
Future<PrefsStore> createPrefsStore() => SharedPrefsStore.open();

/// Speicher im Arbeitsspeicher (Stub und Tests).
class InMemoryPrefsStore implements PrefsStore {
  InMemoryPrefsStore();

  bool _consent = false;
  List<Favorite> _favorites = <Favorite>[];
  Set<String> _favoriteStations = const <String>{};
  double? _volume;
  AppSettings _settings = const AppSettings();
  String? _lastStation;
  List<AlarmRule> _alarms = <AlarmRule>[];
  bool? _telemetry;
  String? _coverCache;
  String? _stationsCache;
  String? _liveCache;

  @override
  bool get storageConsent => _consent;

  @override
  Future<void> setStorageConsent({required bool value}) async =>
      _consent = value;

  @override
  List<Favorite> readFavorites() => _favorites;

  @override
  Future<void> writeFavorites(List<Favorite> favorites) async =>
      _favorites = favorites;

  @override
  Set<String> readFavoriteStations() => _favoriteStations;

  @override
  Future<void> writeFavoriteStations(Set<String> slugs) async =>
      _favoriteStations = Set<String>.unmodifiable(slugs);

  @override
  double? readVolume() => _volume;

  @override
  Future<void> writeVolume(double volume) async => _volume = volume;

  @override
  AppSettings readSettings() => _settings;

  @override
  Future<void> writeSettings(AppSettings settings) async =>
      _settings = settings;

  @override
  String? readLastStation() => _lastStation;

  @override
  Future<void> writeLastStation(String slug) async => _lastStation = slug;

  @override
  List<AlarmRule> readAlarms() => _alarms;

  @override
  Future<void> writeAlarms(List<AlarmRule> alarms) async => _alarms = alarms;

  @override
  bool? readTelemetryConsent() => _telemetry;

  @override
  Future<void> writeTelemetryConsent({required bool? value}) async =>
      _telemetry = value;

  @override
  String? readCoverCache() => _coverCache;

  @override
  Future<void> writeCoverCache(String json) async => _coverCache = json;

  @override
  String? readStationsCache() => _stationsCache;

  @override
  Future<void> writeStationsCache(String json) async => _stationsCache = json;

  @override
  String? readLiveCache() => _liveCache;

  @override
  Future<void> writeLiveCache(String json) async => _liveCache = json;

  @override
  Future<void> clearAll() async {
    _consent = false;
    _favorites = <Favorite>[];
    _favoriteStations = const <String>{};
    _volume = null;
    // "Cover laden: aus" bleibt (wie SharedPrefsStore, R3-P03).
    _settings = AppSettings(loadArtwork: _settings.loadArtwork);
    _lastStation = null;
    _alarms = <AlarmRule>[];
    _telemetry = null;
    _coverCache = null;
    _stationsCache = null;
    _liveCache = null;
  }
}
