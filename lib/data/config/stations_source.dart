import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' show BytesBuilder;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:http/http.dart' as http;
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/stations_config.dart';

/// Mitgelieferte Senderliste (einzige Quelle).
const String stationsAssetPath = 'config/stations.yaml';

/// Laedt die mitgelieferte Senderliste. main() wartet darauf, bevor Audio,
/// CarPlay, Wecker und Deep Links starten; die Datei ist wenige KB gross und
/// liegt im App-Paket (kein Netz).
Future<void> loadBundledStations([AssetBundle? bundle]) async {
  final text = await (bundle ?? rootBundle).loadString(
    stationsAssetPath,
    cache: false,
  );
  installBundledStations(parseStationsConfig(text));
}

/// Ergebnis eines Abrufs (fuer Tests und Protokoll).
enum StationsUpdateOutcome {
  /// Keine Adresse konfiguriert: nur die mitgelieferte Liste.
  disabled,

  /// 304: die gespeicherte Fassung ist aktuell.
  notModified,

  /// Neue Fassung uebernommen.
  applied,

  /// Gueltig, aber gleich der aktuellen Liste.
  unchanged,

  /// Antwort verworfen (falscher Host, zu gross, ungueltig ...).
  rejected,

  /// Netzfehler oder Zeitueberschreitung.
  failed,
}

/// Holt die Senderliste beim Start von der festen Adresse `STATIONS_URL`
/// (zur Bauzeit gesetzt) und wendet sie an, wenn sie die Pruefung besteht.
///
/// Sicherheit:
/// - Nur https, Host exakt der konfigurierte, keine Weiterleitungen (auch
///   nicht auf denselben Host; die Datei liegt fest unter der Adresse).
/// - Groesse vor (Content-Length) und beim Lesen (gestreamt) begrenzt.
/// - Nur YAML/JSON/Text (Content-Type), strenges Schema ([parseStationsConfig]).
/// - Ungueltige oder leere Listen werden nie uebernommen; die bisherige
///   Liste bleibt.
/// - Streams laufen immer ueber `stream.laut.fm/<kuerzel>`; die Datei kann
///   keine Stream-Adressen setzen.
///
/// Speichern: die zuletzt gueltige Fassung (mit ETag) nur nach bestaetigtem
/// Speicher-Hinweis, wie der Cover-Cache ([PrefsStore.writeStationsCache]).
class StationsUpdater {
  StationsUpdater({
    required this.url,
    required this._prefs,
    required this.appVersion,
    this._client,
    bool? conditionalHeaders,
    this.timeout = const Duration(seconds: 10),
  }) : _conditional = conditionalHeaders ?? !kIsWeb;

  /// Feste Adresse oder null (dann kein Netzabruf).
  final Uri? url;

  /// Gespeicherte Fassungen gelten nur fuer dieselbe App-Version; nach einem
  /// Update ist die mitgelieferte Datei mindestens so aktuell.
  final String appVersion;
  final Duration timeout;

  final PrefsStore _prefs;
  final http.Client? _client;
  final bool _conditional;

  /// ETag der aktuell angewendeten Fassung (aus dem Speicher).
  String? _etag;

  /// Prueft `STATIONS_URL`: nur https, mit Host, ohne Zugangsdaten,
  /// Fragment oder fremden Port. Sonst null (kein Abruf).
  static Uri? parseUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        (uri.hasPort && uri.port != 443)) {
      logError('STATIONS_URL ungueltig, Senderliste wird nicht nachgeladen');
      return null;
    }
    return uri;
  }

  /// Wendet die zuletzt gueltig nachgeladene Fassung aus dem Speicher an.
  /// Synchron und ohne Netz (main(), vor dem ersten Bild).
  bool applyCached() {
    final target = url;
    if (target == null) return false;
    final raw = _prefs.readStationsCache();
    if (raw == null || raw.isEmpty) return false;
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, Object?> ||
          data['v'] != appVersion ||
          data['url'] != target.toString() ||
          data['body'] is! String) {
        return false;
      }
      final result = parseStationsConfig(
        data['body']! as String,
        knownLogoAssets: bundledStationLogoAssets,
      );
      if (!result.ok) return false;
      applyStations(result.active.map(stationFromConfig).toList());
      final etag = data['etag'];
      _etag = etag is String && etag.isNotEmpty ? etag : null;
      return true;
    } on FormatException {
      return false;
    }
  }

  /// Holt die aktuelle Fassung im Hintergrund. Wirft nie.
  Future<StationsUpdateOutcome> refresh() async {
    final target = url;
    if (target == null) return StationsUpdateOutcome.disabled;
    final client = _client ?? http.Client();
    try {
      return await _refresh(client, target).timeout(timeout);
    } on TimeoutException {
      return StationsUpdateOutcome.failed;
    } on Object catch (e) {
      logError('Senderliste nicht nachgeladen', e);
      return StationsUpdateOutcome.failed;
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<StationsUpdateOutcome> _refresh(http.Client client, Uri target) async {
    final request = http.Request('GET', target)
      ..followRedirects = false
      ..headers['Accept'] =
          'application/yaml, application/json;q=0.9, text/plain;q=0.5';
    final etag = _etag;
    if (_conditional && etag != null) request.headers['If-None-Match'] = etag;

    final response = await client.send(request);
    final status = response.statusCode;
    if (status == 304 && etag != null) {
      await _discard(response);
      return StationsUpdateOutcome.notModified;
    }
    final reason = rejectReason(response, target);
    if (reason != null) {
      await _discard(response);
      logError('Senderliste verworfen: $reason');
      return StationsUpdateOutcome.rejected;
    }
    final bytes = await readLimited(response.stream, stationsConfigMaxBytes);
    if (bytes == null) {
      logError('Senderliste verworfen: groesser als erlaubt');
      return StationsUpdateOutcome.rejected;
    }
    final result = parseStationsConfigBytes(
      bytes,
      knownLogoAssets: bundledStationLogoAssets,
    );
    if (!result.ok) {
      logError('Senderliste verworfen: ${result.errors.take(3).join('; ')}');
      return StationsUpdateOutcome.rejected;
    }
    final changed = applyStations(
      result.active.map(stationFromConfig).toList(),
    );
    final newEtag = response.headers['etag'];
    _etag = newEtag != null && newEtag.isNotEmpty ? newEtag : null;
    await _prefs.writeStationsCache(
      jsonEncode(<String, Object?>{
        'v': appVersion,
        'url': target.toString(),
        'etag': _etag,
        'body': utf8.decode(bytes),
      }),
    );
    return changed
        ? StationsUpdateOutcome.applied
        : StationsUpdateOutcome.unchanged;
  }

  /// Grund zum Verwerfen einer Antwort, sonst null.
  @visibleForTesting
  static String? rejectReason(http.BaseResponse response, Uri target) {
    final status = response.statusCode;
    if (status >= 300 && status < 400) return 'Weiterleitung ($status)';
    if (status != 200) return 'Status $status';
    // Plattformen, die Weiterleitungen selbst folgen (Browser), melden die
    // endgueltige Adresse: sie muss die konfigurierte sein.
    if (response is http.BaseResponseWithUrl) {
      final finalUrl = response.url;
      if (finalUrl.scheme != 'https' ||
          finalUrl.host.toLowerCase() != target.host.toLowerCase()) {
        return 'fremder Host';
      }
    }
    final length = response.contentLength;
    if (length != null && length > stationsConfigMaxBytes) return 'zu gross';
    final type = (response.headers['content-type'] ?? '').toLowerCase();
    // YAML (oder JSON als Teilmenge); manche Server liefern text/plain.
    const allowed = <String>['yaml', 'json', 'text/plain'];
    if (!allowed.any(type.contains)) return 'kein YAML/JSON ($type)';
    return null;
  }

  /// Liest hoechstens [limit] Bytes; mehr bricht ab und liefert null.
  @visibleForTesting
  static Future<List<int>?> readLimited(Stream<List<int>> stream, int limit) {
    final completer = Completer<List<int>?>();
    final out = BytesBuilder(copy: false);
    late final StreamSubscription<List<int>> sub;
    sub = stream.listen(
      (chunk) {
        out.add(chunk);
        if (out.length > limit) {
          unawaited(sub.cancel());
          if (!completer.isCompleted) completer.complete(null);
        }
      },
      onError: (Object e, StackTrace s) {
        if (!completer.isCompleted) completer.completeError(e, s);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(out.takeBytes());
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  static Future<void> _discard(http.StreamedResponse response) async {
    try {
      await response.stream.listen(null).cancel();
    } on Object {
      // Nichts zu tun.
    }
  }
}
