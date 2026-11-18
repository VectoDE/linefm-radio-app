import 'package:linefm_radio/domain/track.dart';

/// REST-Client fuer api.laut.fm (Spec 3.3). Implementierung: P03.
abstract interface class LautApi {
  Future<Track?> currentSong(String slug);

  /// Genau 10 Songs, neueste zuerst.
  Future<List<Track>> lastSongs(String slug);

  Future<int?> listeners(String slug);

  /// stream_url aus der Station-Antwort, null wenn unbekannt.
  Future<String?> streamUrl(String slug);
}

/// Platzhalter ohne Netzwerkzugriff (Stub bis P03).
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
