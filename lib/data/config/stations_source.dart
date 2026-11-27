import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' show BytesBuilder;

import 'package:crypto/crypto.dart' show sha256;
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
///   Single exception: a `github.com` release download may redirect once to
///   the release asset host ([releaseRedirectTarget]).
/// - Groesse vor (Content-Length) und beim Lesen (gestreamt) begrenzt.
/// - Nur YAML/JSON/Text (Content-Type), strenges Schema ([parseStationsConfig]).
/// - Ungueltige oder leere Listen werden nie uebernommen; die bisherige
///   Liste bleibt.
/// - The SHA-256 of the file must match its line in `SHA256SUMS.txt` from
///   the same directory (for a release: the same release). Missing list,
///   missing line or mismatch: rejected, the previous list stays.
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
    final etag = _etag;
    http.Request build(Uri uri) {
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers['Accept'] =
            'application/yaml, application/json;q=0.9, text/plain;q=0.5';
      if (_conditional && etag != null) {
        request.headers['If-None-Match'] = etag;
      }
      return request;
    }

    var response = await client.send(build(target));
    // A GitHub release download answers with one redirect to the release
    // asset host. That single hop is the only redirect ever followed.
    final hop = releaseRedirectTarget(response, target);
    if (hop != null) {
      await _discard(response);
      response = await client.send(build(hop));
    }
    final status = response.statusCode;
    if (status == 304 && etag != null) {
      await _discard(response);
      return StationsUpdateOutcome.notModified;
    }
    final reason = rejectReason(response, target, requested: hop);
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
    final checksum = await _verifyChecksum(client, target, bytes);
    if (checksum != null) {
      logError('Senderliste verworfen: $checksum');
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

  /// Upper bound for SHA256SUMS.txt (one line per release file).
  @visibleForTesting
  static const int checksumsMaxBytes = 64 * 1024;

  /// Address of the checksum list next to [target]: same directory, file
  /// `SHA256SUMS.txt` (for a release download the same release).
  @visibleForTesting
  static Uri checksumsUrl(Uri target) {
    final r = target.resolve('SHA256SUMS.txt');
    return Uri(
      scheme: r.scheme,
      host: r.host,
      port: r.hasPort ? r.port : null,
      path: r.path,
    );
  }

  /// Fetches SHA256SUMS.txt (same rules as the list itself, including the
  /// one release redirect, no conditional request) and compares the SHA-256
  /// of [bytes] with the line for the list's file name. Returns the reason
  /// for a rejection, or null if the checksum matches.
  Future<String?> _verifyChecksum(
    http.Client client,
    Uri target,
    List<int> bytes,
  ) async {
    final sumsUrl = checksumsUrl(target);
    http.Request build(Uri uri) => http.Request('GET', uri)
      ..followRedirects = false
      ..headers['Accept'] = 'text/plain, application/octet-stream;q=0.5';
    var response = await client.send(build(sumsUrl));
    final hop = releaseRedirectTarget(response, sumsUrl);
    if (hop != null) {
      await _discard(response);
      response = await client.send(build(hop));
    }
    final reason = rejectReason(response, sumsUrl, requested: hop);
    if (reason != null) {
      await _discard(response);
      return 'Pruefsumme nicht abrufbar ($reason)';
    }
    final raw = await readLimited(response.stream, checksumsMaxBytes);
    if (raw == null) return 'Pruefsummenliste zu gross';
    final name = target.pathSegments.isEmpty ? '' : target.pathSegments.last;
    final expected = expectedChecksum(
      utf8.decode(raw, allowMalformed: true),
      name,
    );
    if (expected == null) return 'keine Pruefsumme fuer $name';
    final actual = sha256.convert(bytes).toString();
    return actual == expected ? null : 'Pruefsumme stimmt nicht';
  }

  /// Hex SHA-256 for [fileName] from `sha256sum` output (`<hex>  <name>` or
  /// `<hex> *<name>`), lower case; null if missing or malformed.
  @visibleForTesting
  static String? expectedChecksum(String sums, String fileName) {
    if (fileName.isEmpty) return null;
    final line = RegExp(r'^([0-9a-fA-F]{64}) [ *](.+)$');
    for (final raw in const LineSplitter().convert(sums)) {
      final m = line.firstMatch(raw.trimRight());
      if (m != null && m.group(2) == fileName) return m.group(1)!.toLowerCase();
    }
    return null;
  }

  /// Grund zum Verwerfen einer Antwort, sonst null.
  @visibleForTesting
  static String? rejectReason(
    http.BaseResponse response,
    Uri target, {
    Uri? requested,
  }) {
    final status = response.statusCode;
    if (status >= 300 && status < 400) return 'Weiterleitung ($status)';
    if (status != 200) return 'Status $status';
    // Plattformen, die Weiterleitungen selbst folgen (Browser), melden die
    // endgueltige Adresse: sie muss die konfigurierte sein.
    bool isReleaseHost(Uri uri) =>
        _isGitHub(target) &&
        uri.scheme == 'https' &&
        releaseAssetHosts.contains(uri.host.toLowerCase());
    var fromReleaseHost = requested != null && isReleaseHost(requested);
    if (response is http.BaseResponseWithUrl) {
      final finalUrl = response.url;
      final host = finalUrl.host.toLowerCase();
      fromReleaseHost = isReleaseHost(finalUrl);
      if (finalUrl.scheme != 'https' ||
          (host != target.host.toLowerCase() && !fromReleaseHost)) {
        return 'fremder Host';
      }
    }
    final length = response.contentLength;
    if (length != null && length > stationsConfigMaxBytes) return 'zu gross';
    final type = (response.headers['content-type'] ?? '').toLowerCase();
    // YAML (oder JSON als Teilmenge); manche Server liefern text/plain.
    // The release asset host serves every asset as octet-stream; the strict
    // schema check below still applies.
    final allowed = <String>[
      'yaml',
      'json',
      'text/plain',
      if (fromReleaseHost) 'application/octet-stream',
    ];
    if (!allowed.any(type.contains)) return 'kein YAML/JSON ($type)';
    return null;
  }

  /// Hosts GitHub redirects release downloads to.
  @visibleForTesting
  static const Set<String> releaseAssetHosts = <String>{
    'objects.githubusercontent.com',
    'release-assets.githubusercontent.com',
  };

  static bool _isGitHub(Uri target) =>
      target.host.toLowerCase() == 'github.com';

  /// The one allowed redirect: from a `github.com` release download to the
  /// release asset host, https only, without credentials or a custom port.
  /// Returns the next address, otherwise null (the response is then judged
  /// by [rejectReason], which rejects every other redirect).
  @visibleForTesting
  static Uri? releaseRedirectTarget(http.BaseResponse response, Uri target) {
    const redirects = <int>{301, 302, 303, 307, 308};
    if (!_isGitHub(target) || !redirects.contains(response.statusCode)) {
      return null;
    }
    final location = response.headers['location'];
    if (location == null) return null;
    final next = Uri.tryParse(location.trim());
    if (next == null ||
        next.scheme != 'https' ||
        !releaseAssetHosts.contains(next.host.toLowerCase()) ||
        next.userInfo.isNotEmpty ||
        (next.hasPort && next.port != 443)) {
      return null;
    }
    return next;
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
