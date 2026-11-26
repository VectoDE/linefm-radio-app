import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:linefm_radio/data/api/http_cache.dart';
import 'package:linefm_radio/data/api/laut_parsers.dart';
import 'package:linefm_radio/domain/schedule_slot.dart';
import 'package:linefm_radio/domain/track.dart';

/// REST client for api.laut.fm (spec 3.3).
abstract interface class LautApi {
  Future<Track?> currentSong(String slug);

  /// Exactly 10 songs, newest first.
  Future<List<Track>> lastSongs(String slug);

  Future<int?> listeners(String slug);

  /// Weekly schedule of the station; empty if laut.fm delivers none.
  Future<List<ScheduleSlot>> schedule(String slug);

  /// stream_url from the station response, null if unknown.
  Future<String?> streamUrl(String slug);
}

/// Error of a laut.fm request (HTTP status other than 200 or broken
/// JSON). Network errors without a cache entry surface as an exception from
/// `package:http`.
class LautApiException implements Exception {
  const LautApiException(this.uri, this.message, {this.statusCode});

  final Uri uri;
  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'LautApiException($message${statusCode == null ? '' : ', $statusCode'}'
      ', $uri)';
}

/// Real implementation on top of [HttpCache].
class HttpLautApi implements LautApi {
  HttpLautApi({HttpCache? cache, Uri? baseUri})
    : cache = cache ?? HttpCache(),
      _base = baseUri ?? Uri.parse('https://api.laut.fm');

  final HttpCache cache;
  final Uri _base;

  Uri _station(String slug, [String? endpoint]) =>
      _base.replace(pathSegments: <String>['station', slug, ?endpoint]);

  @override
  Future<Track?> currentSong(String slug) async =>
      (await currentSongDetail(slug))?.track;

  /// Like [currentSong], additionally with the live flag (see [LautSong]).
  Future<LautSong?> currentSongDetail(String slug) async =>
      LautParsers.parseSongDetail(
        await _getJson(_station(slug, 'current_song')),
      );

  @override
  Future<List<Track>> lastSongs(String slug) async =>
      LautParsers.parseSongList(await _getJson(_station(slug, 'last_songs')));

  @override
  Future<int?> listeners(String slug) async =>
      LautParsers.parseListeners(await _getJson(_station(slug, 'listeners')));

  @override
  Future<List<ScheduleSlot>> schedule(String slug) async =>
      LautParsers.parseSchedule(
        await _getJson(
          _station(slug, 'schedule'),
          emptyBodyAs: const <Object?>[],
        ),
      );

  @override
  Future<String?> streamUrl(String slug) async =>
      LautParsers.parseStreamUrl(await _getJson(_station(slug)));

  /// [emptyBodyAs]: result for an empty body with status 200 (laut.fm sends
  /// that for stations without a schedule); otherwise an empty body is an error.
  Future<Object?> _getJson(Uri uri, {Object? emptyBodyAs}) async {
    final http.Response response = await cache.get(uri);
    if (response.statusCode != 200) {
      throw LautApiException(
        uri,
        'HTTP-Fehler',
        statusCode: response.statusCode,
      );
    }
    if (emptyBodyAs != null && response.bodyBytes.isEmpty) return emptyBodyAs;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (e) {
      throw LautApiException(uri, 'Ungueltiges JSON: ${e.message}');
    }
  }

  void close() => cache.close();
}

/// Placeholder without network access (tests, previews).
class StubLautApi implements LautApi {
  const StubLautApi();

  @override
  Future<Track?> currentSong(String slug) async => null;

  @override
  Future<List<Track>> lastSongs(String slug) async => const <Track>[];

  @override
  Future<int?> listeners(String slug) async => null;

  @override
  Future<List<ScheduleSlot>> schedule(String slug) async =>
      const <ScheduleSlot>[];

  @override
  Future<String?> streamUrl(String slug) async => null;
}
