import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';

/// In-memory store for tests; production uses SharedPrefsStore.
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
    // "Cover laden: aus" bleibt (wie SharedPrefsStore).
    _settings = AppSettings(loadArtwork: _settings.loadArtwork);
    _lastStation = null;
    _alarms = <AlarmRule>[];
    _telemetry = null;
    _coverCache = null;
    _stationsCache = null;
    _liveCache = null;
  }
}
