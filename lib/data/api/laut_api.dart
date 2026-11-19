import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:linefm_radio/data/api/http_cache.dart';
import 'package:linefm_radio/data/api/laut_parsers.dart';
import 'package:linefm_radio/domain/track.dart';

/// REST-Client fuer api.laut.fm (Spec 3.3).
abstract interface class LautApi {
  Future<Track?> currentSong(String slug);

  /// Genau 10 Songs, neueste zuerst.
  Future<List<Track>> lastSongs(String slug);

  Future<int?> listeners(String slug);

  /// stream_url aus der Station-Antwort, null wenn unbekannt.
  Future<String?> streamUrl(String slug);
}

/// Fehler einer laut.fm-Anfrage (HTTP-Status ungleich 200 oder kaputtes
/// JSON). Netzwerkfehler ohne Cache-Eintrag kommen als Exception von
/// `package:http` durch.
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

/// Echte Implementierung ueber [HttpCache].
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

  /// Wie [currentSong], zusaetzlich mit Live-Kennung (siehe [LautSong]).
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
  Future<String?> streamUrl(String slug) async =>
      LautParsers.parseStreamUrl(await _getJson(_station(slug)));

  Future<Object?> _getJson(Uri uri) async {
    final http.Response response = await cache.get(uri);
    if (response.statusCode != 200) {
      throw LautApiException(
        uri,
        'HTTP-Fehler',
        statusCode: response.statusCode,
      );
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (e) {
      throw LautApiException(uri, 'Ungueltiges JSON: ${e.message}');
    }
  }

  void close() => cache.close();
}

/// Platzhalter ohne Netzwerkzugriff (Tests, Previews).
class StubLautApi implements LautApi {
  const StubLautApi();

  @override
  Future<Track?> currentSong(String slug) async => null;

  @override
  Future<List<Track>> lastSongs(String slug) async => const <Track>[];

  @override
  Future<int?> listeners(String slug) async => null;

  @override
  Future<String?> streamUrl(String slug) async => null;
}
