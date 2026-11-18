import 'package:linefm_radio/domain/track.dart';

/// Titelwechsel-Nachricht des WebSockets, bereits auf unsere Slugs gefiltert.
class SongChange {
  const SongChange({required this.stationSlug, required this.track});

  final String stationSlug;
  final Track track;
}

/// WebSocket wss://api.laut.fm/song_change.ws.json mit Reconnect und
/// Traffic-Waechter (Spec 3.3). Stub, P03.
abstract interface class SongChangeSocket {
  Stream<SongChange> get changes;

  Future<void> connect();

  Future<void> close();
}

class StubSongChangeSocket implements SongChangeSocket {
  const StubSongChangeSocket();

  @override
  Stream<SongChange> get changes => const Stream<SongChange>.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> close() async {}
}
