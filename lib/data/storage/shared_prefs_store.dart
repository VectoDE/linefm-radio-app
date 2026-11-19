import 'dart:convert';

import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorite_stations_logic.dart';
import 'package:linefm_radio/domain/favorites/favorites_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Speicherschluessel. Die ersten sechs entsprechen den Schluesseln der
/// Web-App (nur Namen, die Werte sind hier typisiert), `shared_preferences`
/// stellt auf Web/Native ein eigenes Praefix (`flutter.`) davor.
abstract final class PrefsKeys {
  static const String favorites = 'linefm-favorites';
  static const String volume = 'linefm-volume';
  static const String storageConsent = 'linefm-storage-notice-dismissed';
  static const String marquee = 'linefm-setting-marquee';
  static const String rememberVolume = 'linefm-setting-remember-volume';
  static const String lastStation = 'linefm-last-station';

  static const String autoplay = 'linefm-setting-autoplay';
  static const String closeToTray = 'linefm-setting-close-to-tray';
  static const String themeMode = 'linefm-setting-theme';
  static const String alarms = 'linefm-alarms';
  static const String telemetryConsent = 'linefm-telemetry-consent';
  static const String coverCache = 'linefm-cover-cache';

  /// Favoriten-Sender (Issue #42). Gibt es in der Web-App nicht.
  static const String favoriteStations = 'linefm-favorite-stations';

  /// Alle Daten-Schluessel, also alles ausser der Speicher-Bestaetigung.
  static const List<String> data = <String>[
    favorites,
    favoriteStations,
    volume,
    marquee,
    rememberVolume,
    lastStation,
    autoplay,
    closeToTray,
    themeMode,
    alarms,
    telemetryConsent,
    coverCache,
  ];
}

/// [PrefsStore] auf Basis von `shared_preferences` (Web: localStorage).
///
/// Verhalten wie die Web-App (`readStoredValue`/`storeValue`/
/// `clearAppStorage`):
/// * Ohne Speicher-Bestaetigung wird nichts geschrieben, Lesen liefert die
///   Standardwerte. Beim Start ohne Bestaetigung werden Altdaten entfernt.
/// * [clearAll] loescht alle Daten samt Bestaetigung.
/// * Die Telemetrie-Einwilligung zaehlt ebenfalls als Speicherung und folgt
///   derselben Regel; ohne Bestaetigung wird die Entscheidung nicht gemerkt.
/// * Die Lautstaerke wird nur gelesen und geschrieben, solange
///   "Lautstaerke merken" aktiv ist.
///
/// Lesen ist synchron aus dem Cache von `SharedPreferences`; Schreibfehler
/// werden wie in der Web-App verschluckt (nur Debug-Log).
class SharedPrefsStore implements PrefsStore {
  SharedPrefsStore(this._prefs)
    : _consent = _readBool(_prefs, PrefsKeys.storageConsent) ?? false;

  /// Oeffnet den Speicher und raeumt ohne Bestaetigung Altdaten weg.
  static Future<SharedPrefsStore> open() async {
    final store = SharedPrefsStore(await SharedPreferences.getInstance());
    if (!store._consent) await store._removeData();
    return store;
  }

  final SharedPreferences _prefs;
  bool _consent;

  @override
  bool get storageConsent => _consent;

  @override
  Future<void> setStorageConsent({required bool value}) async {
    _consent = value;
    if (value) {
      await _write(() => _prefs.setBool(PrefsKeys.storageConsent, true));
    } else {
      await _removeData();
      await _write(() => _prefs.remove(PrefsKeys.storageConsent));
    }
  }

  @override
  List<Favorite> readFavorites() {
    if (!_consent) return <Favorite>[];
    return FavoritesLogic.decode(_readString(PrefsKeys.favorites));
  }

  @override
  Future<void> writeFavorites(List<Favorite> favorites) async {
    if (!_consent) return;
    await _write(
      () => _prefs.setString(
        PrefsKeys.favorites,
        FavoritesLogic.encode(favorites),
      ),
    );
  }

  @override
  Set<String> readFavoriteStations() {
    if (!_consent) return const <String>{};
    return FavoriteStationsLogic.decode(
      _readString(PrefsKeys.favoriteStations),
    );
  }

  @override
  Future<void> writeFavoriteStations(Set<String> slugs) async {
    if (!_consent) return;
    await _write(
      () => _prefs.setString(
        PrefsKeys.favoriteStations,
        FavoriteStationsLogic.encode(slugs),
      ),
    );
  }

  @override
  double? readVolume() {
    if (!_consent || !readSettings().rememberVolume) return null;
    final value = _prefs.get(PrefsKeys.volume);
    final volume = switch (value) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s),
      _ => null,
    };
    if (volume == null || !volume.isFinite) return null;
    return volume.clamp(0.0, 1.0);
  }

  @override
  Future<void> writeVolume(double volume) async {
    if (!_consent || !readSettings().rememberVolume || !volume.isFinite) return;
    await _write(
      () => _prefs.setDouble(PrefsKeys.volume, volume.clamp(0.0, 1.0)),
    );
  }

  @override
  AppSettings readSettings() {
    const defaults = AppSettings();
    if (!_consent) return defaults;
    return AppSettings.fromJson(<String, Object?>{
      'marquee': _readBool(_prefs, PrefsKeys.marquee),
      'rememberVolume': _readBool(_prefs, PrefsKeys.rememberVolume),
      'autoplay': _readBool(_prefs, PrefsKeys.autoplay),
      'closeToTray': _readBool(_prefs, PrefsKeys.closeToTray),
      'themeMode': _readString(PrefsKeys.themeMode),
    });
  }

  @override
  Future<void> writeSettings(AppSettings settings) async {
    if (!_consent) return;
    await _write(() async {
      await _prefs.setBool(PrefsKeys.marquee, settings.marquee);
      await _prefs.setBool(PrefsKeys.rememberVolume, settings.rememberVolume);
      await _prefs.setBool(PrefsKeys.autoplay, settings.autoplay);
      await _prefs.setBool(PrefsKeys.closeToTray, settings.closeToTray);
      await _prefs.setString(PrefsKeys.themeMode, settings.themeMode.name);
      return true;
    });
  }

  @override
  String? readLastStation() =>
      _consent ? _readString(PrefsKeys.lastStation) : null;

  @override
  Future<void> writeLastStation(String slug) async {
    if (!_consent) return;
    await _write(() => _prefs.setString(PrefsKeys.lastStation, slug));
  }

  @override
  List<AlarmRule> readAlarms() {
    if (!_consent) return <AlarmRule>[];
    final json = _readString(PrefsKeys.alarms);
    if (json == null || json.isEmpty) return <AlarmRule>[];
    try {
      final data = jsonDecode(json);
      if (data is! List) return <AlarmRule>[];
      return <AlarmRule>[for (final item in data) ?AlarmRule.tryFromJson(item)];
    } on FormatException {
      return <AlarmRule>[];
    }
  }

  @override
  Future<void> writeAlarms(List<AlarmRule> alarms) async {
    if (!_consent) return;
    await _write(
      () => _prefs.setString(
        PrefsKeys.alarms,
        jsonEncode(alarms.map((a) => a.toJson()).toList()),
      ),
    );
  }

  @override
  bool? readTelemetryConsent() =>
      _consent ? _readBool(_prefs, PrefsKeys.telemetryConsent) : null;

  @override
  Future<void> writeTelemetryConsent({required bool? value}) async {
    if (!_consent) return;
    await _write(
      () => value == null
          ? _prefs.remove(PrefsKeys.telemetryConsent)
          : _prefs.setBool(PrefsKeys.telemetryConsent, value),
    );
  }

  @override
  String? readCoverCache() =>
      _consent ? _readString(PrefsKeys.coverCache) : null;

  @override
  Future<void> writeCoverCache(String json) async {
    if (!_consent) return;
    await _write(() => _prefs.setString(PrefsKeys.coverCache, json));
  }

  @override
  Future<void> clearAll() async {
    _consent = false;
    await _removeData();
    await _write(() => _prefs.remove(PrefsKeys.storageConsent));
  }

  Future<void> _removeData() async {
    for (final key in PrefsKeys.data) {
      await _write(() => _prefs.remove(key));
    }
  }

  String? _readString(String key) {
    final value = _prefs.get(key);
    return value is String ? value : null;
  }

  Future<void> _write(Future<bool> Function() action) async {
    try {
      await action();
    } on Object catch (error, stack) {
      logError('Speichern fehlgeschlagen', error, stack);
    }
  }
}

/// Liest einen Wahrheitswert tolerant: `bool` oder die Texte "true"/"false"
/// (so schreibt die Web-App).
bool? _readBool(SharedPreferences prefs, String key) =>
    switch (prefs.get(key)) {
      final bool b => b,
      'true' => true,
      'false' => false,
      _ => null,
    };
