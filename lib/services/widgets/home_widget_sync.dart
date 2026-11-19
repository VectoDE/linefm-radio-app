import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';

/// Schreibt Widget-Daten (home_widget). Android: P16, iOS: P17.
abstract interface class HomeWidgetSync {
  Future<void> update({Station? station, Track? track, required bool playing});
}

class NoopHomeWidgetSync implements HomeWidgetSync {
  const NoopHomeWidgetSync();

  @override
  Future<void> update({
    Station? station,
    Track? track,
    required bool playing,
  }) async {}
}

/// Schluessel im Widget-Speicher (`HomeWidgetPreferences`). Der Kotlin-
/// Provider `de.linefm.app.widget.LinefmWidgetProvider` liest dieselben
/// Namen (`WidgetKeys` dort).
abstract final class HomeWidgetKeys {
  static const String stationSlug = 'station_slug';
  static const String stationName = 'station_name';
  static const String title = 'title';
  static const String artist = 'artist';
  static const String playing = 'playing';
  static const String coverPath = 'cover_path';
  static const String idleText = 'idle_text';
  static const String playLabel = 'play_label';
  static const String stopLabel = 'stop_label';
}

/// Voll qualifizierter Name des Android-Widget-Providers.
const String androidWidgetProvider =
    'de.linefm.app.widget.LinefmWidgetProvider';

/// WidgetKit-Art (`kind`) des iOS-Widgets (`ios/LinefmWidget`).
const String iosWidgetKind = 'LinefmWidget';

/// App Group, ueber die App und iOS-Widget die Daten teilen (Spec 2.2).
const String iosAppGroupId = 'group.de.linefm.app';

/// Datei-Schluessel des Covers (home_widget legt es unter
/// `<App-Support>/home_widget/linefm_cover.jpg` ab).
const String _coverFileKey = 'linefm_cover';

/// Groesste Cover-Datei, die geladen wird (iTunes 300x300 liegt bei ~30 KB).
const int _maxCoverBytes = 1024 * 1024;

/// Zugriff auf home_widget, austauschbar fuer Tests.
abstract interface class HomeWidgetBackend {
  Future<void> save(String key, Object? value);
  Future<void> saveCover(Uint8List bytes);
  Future<void> refresh();
}

class _PluginBackend implements HomeWidgetBackend {
  const _PluginBackend();

  @override
  Future<void> save(String key, Object? value) =>
      HomeWidget.saveWidgetData<Object>(key, value);

  @override
  Future<void> saveCover(Uint8List bytes) =>
      HomeWidget.saveFile(_coverFileKey, bytes, extension: 'jpg').then(
        (path) =>
            HomeWidget.saveWidgetData<String>(HomeWidgetKeys.coverPath, path),
      );

  @override
  Future<void> refresh() => HomeWidget.updateWidget(
    qualifiedAndroidName: androidWidgetProvider,
    iOSName: iosWidgetKind,
  );
}

/// Laedt Cover-Bytes; null bei Fehler.
typedef CoverFetcher = Future<Uint8List?> Function(Uri url);

/// Homescreen-Widget unter Android und iOS (Spec 2.2): Sender, Titel, Kuenstler,
/// Wiedergabestatus und ein lokal gespeichertes Cover (300x300). Der
/// Play-/Stop-Knopf im Widget entscheidet anhand von `playing`, ob er die
/// Wiedergabe ueber die Medientaste stoppt oder die App per
/// `linefm://play?station=<slug>` startet.
///
/// Schreibt nur bei Aenderungen; das Cover wird nur bei neuer Adresse
/// geladen. Fehler werden protokolliert und nie geworfen.
class AndroidHomeWidgetSync implements HomeWidgetSync {
  AndroidHomeWidgetSync({
    HomeWidgetBackend? backend,
    CoverFetcher? fetchCover,
    Locale Function()? locale,
  }) : _backend = backend ?? const _PluginBackend(),
       _fetchCover = fetchCover ?? _httpFetchCover,
       _locale = locale ?? (() => PlatformDispatcher.instance.locale);

  final HomeWidgetBackend _backend;
  final CoverFetcher _fetchCover;
  final Locale Function() _locale;

  Map<String, Object?>? _written;
  Uri? _coverUrl;
  Future<void> _pending = Future<void>.value();

  @override
  Future<void> update({Station? station, Track? track, required bool playing}) {
    // Nacheinander, damit ein langsamer Cover-Abruf keinen neueren Stand
    // ueberschreibt.
    final next = _pending.then(
      (_) => _apply(station: station, track: track, playing: playing),
    );
    _pending = next.catchError((Object _) {});
    return _pending;
  }

  Future<void> _apply({
    Station? station,
    Track? track,
    required bool playing,
  }) async {
    try {
      final values = widgetValues(
        station: station,
        track: track,
        playing: playing,
        l10n: lookupAppLocalizations(_supported(_locale())),
      );
      final coverUrl = coverUrlFor(track);
      final coverChanged = coverUrl != _coverUrl;
      final previous = _written;
      if (!coverChanged && previous != null && _sameMap(previous, values)) {
        return;
      }
      for (final entry in values.entries) {
        if (previous == null || previous[entry.key] != entry.value) {
          await _backend.save(entry.key, entry.value);
        }
      }
      _written = values;
      if (coverChanged) {
        _coverUrl = coverUrl;
        final bytes = coverUrl == null ? null : await _fetchCover(coverUrl);
        if (bytes == null) {
          // Ohne Cover zeigt das Widget das gebuendelte Senderlogo.
          await _backend.save(HomeWidgetKeys.coverPath, null);
        } else {
          await _backend.saveCover(bytes);
        }
      }
      await _backend.refresh();
    } on Object catch (e, st) {
      logError('Homescreen-Widget nicht aktualisiert', e, st);
    }
  }

  /// Werte fuer den Widget-Speicher.
  @visibleForTesting
  static Map<String, Object?> widgetValues({
    required Station? station,
    required Track? track,
    required bool playing,
    required AppLocalizations l10n,
  }) {
    final hasTrack =
        track != null && (track.title.isNotEmpty || track.artist.isNotEmpty);
    return <String, Object?>{
      HomeWidgetKeys.stationSlug: station?.slug,
      HomeWidgetKeys.stationName: station?.displayName,
      HomeWidgetKeys.title: hasTrack ? track.title : null,
      HomeWidgetKeys.artist: hasTrack ? track.artist : null,
      HomeWidgetKeys.playing: playing,
      HomeWidgetKeys.idleText: l10n.widgetIdle,
      HomeWidgetKeys.playLabel: l10n.playerStart,
      HomeWidgetKeys.stopLabel: l10n.playerStop,
    };
  }

  /// Cover-Adresse fuer das Widget: nur https, iTunes-Bilder in 300x300.
  @visibleForTesting
  static Uri? coverUrlFor(Track? track) {
    final raw = track?.artworkUrl;
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    final path = uri.path.replaceFirstMapped(
      RegExp(r'/(\d+)x(\d+)(bb)?\.(jpg|jpeg|png)$'),
      (m) => '/300x300${m[3] ?? ''}.${m[4]}',
    );
    return uri.replace(path: path);
  }

  static Locale _supported(Locale locale) =>
      AppLocalizations.supportedLocales.any(
        (l) => l.languageCode == locale.languageCode,
      )
      ? Locale(locale.languageCode)
      : const Locale('en');

  static bool _sameMap(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

Future<Uint8List?> _httpFetchCover(Uri url) async {
  final client = http.Client();
  try {
    final response = await client.get(url).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final bytes = response.bodyBytes;
    if (bytes.isEmpty || bytes.length > _maxCoverBytes) return null;
    return bytes;
  } on Object catch (e) {
    logError('Widget-Cover nicht geladen', e);
    return null;
  } finally {
    client.close();
  }
}

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Passende Umsetzung fuer die Plattform (Android und iOS: home_widget,
/// sonst No-Op). iOS liest dieselben Schluessel aus der App Group
/// [iosAppGroupId] (`ios/LinefmWidget/LinefmWidget.swift`).
HomeWidgetSync createHomeWidgetSync() =>
    _isAndroid || _isIos ? AndroidHomeWidgetSync() : const NoopHomeWidgetSync();

/// Initialisiert das Homescreen-Widget: Beim Start laeuft noch nichts,
/// deshalb wird ein evtl. veralteter Status "spielt" (App beendet waehrend
/// der Wiedergabe) zurueckgesetzt. Danach schreibt der PlayerController
/// ueber [HomeWidgetSync.update].
Future<void> initHomeWidget() async {
  if (!_isAndroid && !_isIos) return;
  try {
    if (_isIos) await HomeWidget.setAppGroupId(iosAppGroupId);
    await HomeWidget.saveWidgetData<bool>(HomeWidgetKeys.playing, false);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: androidWidgetProvider,
      iOSName: iosWidgetKind,
    );
  } on Object catch (e) {
    logError('Homescreen-Widget nicht initialisiert', e);
  }
}
