import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:linefm_radio/core/clock.dart';

/// In-Memory-HTTP-Cache fuer api.laut.fm (Spec 3.3).
///
/// Gemessenes Verhalten von api.laut.fm (18.11.2026):
/// - `current_song`/`last_songs`: `Cache-Control: public, must-revalidate`
///   OHNE `max-age`, dafuer `Expires` (bei `current_song` = Songende) und
///   `Date`. Frische deshalb aus `Expires - Date`.
/// - `station`, `listeners`: `max-age=N` plus `Age`.
/// - Schwache `ETag`s; `If-None-Match` liefert `304` (station, listeners),
///   `If-Modified-Since` liefert nie `304`, wird aber zusaetzlich gesendet,
///   falls laut.fm das spaeter auswertet.
/// - CORS erlaubt nur `If-Modified-Since` als Anfrage-Header. Auf Web setzt
///   der Cache deshalb keine Bedingungs-Header (sonst Preflight bzw.
///   CORS-Fehler); dort uebernimmt der Browser-Cache die Revalidierung.
///
/// Gleiche URL in Arbeit -> selbes Future (Deduplizierung). Bei
/// Netzwerkfehlern wird ein vorhandener (auch veralteter) Eintrag geliefert;
/// er traegt dann den Header [staleHeader]. Jede Anfrage bricht nach
/// [timeout] ab und zaehlt dann als Netzwerkfehler (S5).
class HttpCache {
  HttpCache({
    http.Client? client,
    this._clock = const SystemClock(),
    bool? conditionalHeaders,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _conditional = conditionalHeaders ?? !kIsWeb;

  /// Markiert eine Antwort, die wegen eines Netzwerkfehlers aus dem
  /// veralteten Cache kommt.
  static const String staleHeader = 'x-linefm-stale';

  /// Markiert eine Antwort, die ohne Netzwerkzugriff aus dem Cache kommt.
  static const String cacheHeader = 'x-linefm-cache';

  /// Hoechstdauer einer Anfrage.
  final Duration timeout;

  final http.Client _client;
  final Clock _clock;
  final bool _conditional;
  final Map<Uri, _Entry> _entries = <Uri, _Entry>{};
  final Map<Uri, Future<http.Response>> _inFlight =
      <Uri, Future<http.Response>>{};

  /// Anzahl der echten Netzwerkanfragen (fuer Tests und Diagnose).
  int networkRequests = 0;

  Future<http.Response> get(Uri uri) {
    final entry = _entries[uri];
    final now = _clock.now();
    if (entry != null && now.isBefore(entry.freshUntil)) {
      return Future<http.Response>.value(
        entry.toResponse(<String, String>{cacheHeader: 'hit'}),
      );
    }
    final running = _inFlight[uri];
    if (running != null) return running;
    // Block-Rumpf: remove() liefert dieses Future zurueck; als Rueckgabewert
    // von whenComplete wuerde es auf sich selbst warten (Deadlock).
    final future = _fetch(uri, entry).whenComplete(() {
      _inFlight.remove(uri);
    });
    _inFlight[uri] = future;
    return future;
  }

  /// Verwirft alle Eintraege (z. B. nach "Speicher loeschen").
  void clear() => _entries.clear();

  void close() => _client.close();

  Future<http.Response> _fetch(Uri uri, _Entry? entry) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (_conditional && entry != null) {
      final etag = entry.headers['etag'];
      if (etag != null && etag.isNotEmpty) headers['If-None-Match'] = etag;
      final since = entry.headers['last-modified'] ?? entry.headers['date'];
      if (since != null && since.isNotEmpty) {
        headers['If-Modified-Since'] = since;
      }
    }

    final http.Response response;
    try {
      networkRequests++;
      response = await _client.get(uri, headers: headers).timeout(timeout);
    } on Object {
      if (entry != null) {
        return entry.toResponse(<String, String>{staleHeader: '1'});
      }
      rethrow;
    }

    final receivedAt = _clock.now();
    if (response.statusCode == 304 && entry != null) {
      final merged = <String, String>{...entry.headers, ...response.headers};
      final refreshed = _Entry(
        statusCode: entry.statusCode,
        bodyBytes: entry.bodyBytes,
        headers: merged,
        freshUntil: freshUntil(merged, receivedAt),
      );
      _entries[uri] = refreshed;
      return refreshed.toResponse(const <String, String>{});
    }

    if (response.statusCode == 200 && !_noStore(response.headers)) {
      _entries[uri] = _Entry(
        statusCode: response.statusCode,
        bodyBytes: response.bodyBytes,
        headers: response.headers,
        freshUntil: freshUntil(response.headers, receivedAt),
      );
    }
    return response;
  }

  static bool _noStore(Map<String, String> headers) =>
      (headers['cache-control'] ?? '').toLowerCase().contains('no-store');

  /// Frische nach RFC 9111: `max-age - Age`, sonst `Expires - Date`,
  /// sonst sofort veraltet. Header-Namen in Kleinschreibung (package:http).
  static DateTime freshUntil(Map<String, String> headers, DateTime receivedAt) {
    final cacheControl = (headers['cache-control'] ?? '').toLowerCase();
    if (cacheControl.contains('no-cache') ||
        cacheControl.contains('no-store')) {
      return receivedAt;
    }
    final maxAge = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
    final age = int.tryParse((headers['age'] ?? '').trim()) ?? 0;
    if (maxAge != null) {
      final seconds = int.parse(maxAge.group(1)!) - age;
      return seconds > 0
          ? receivedAt.add(Duration(seconds: seconds))
          : receivedAt;
    }
    final expires = parseHttpDate(headers['expires']);
    final date = parseHttpDate(headers['date']);
    if (expires != null && date != null) {
      final lifetime = expires.difference(date);
      return lifetime > Duration.zero ? receivedAt.add(lifetime) : receivedAt;
    }
    return receivedAt;
  }

  static const List<String> _months = <String>[
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];

  static final RegExp _imfDate = RegExp(
    r'(\d{1,2})[ -]([A-Za-z]{3})[ -](\d{2,4}) (\d{2}):(\d{2}):(\d{2}) GMT',
  );

  /// HTTP-Datum (RFC 9110 IMF-fixdate, auch RFC 850), ohne dart:io,
  /// damit der Code auf Web laeuft.
  static DateTime? parseHttpDate(String? value) {
    if (value == null) return null;
    final m = _imfDate.firstMatch(value);
    if (m == null) return null;
    final month = _months.indexOf(m.group(2)!.toLowerCase());
    if (month < 0) return null;
    var year = int.parse(m.group(3)!);
    if (year < 100) year += year < 70 ? 2000 : 1900;
    return DateTime.utc(
      year,
      month + 1,
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6)!),
    );
  }
}

class _Entry {
  const _Entry({
    required this.statusCode,
    required this.bodyBytes,
    required this.headers,
    required this.freshUntil,
  });

  final int statusCode;
  final List<int> bodyBytes;
  final Map<String, String> headers;
  final DateTime freshUntil;

  http.Response toResponse(Map<String, String> extra) => http.Response.bytes(
    bodyBytes,
    statusCode,
    headers: <String, String>{...headers, ...extra},
  );
}
