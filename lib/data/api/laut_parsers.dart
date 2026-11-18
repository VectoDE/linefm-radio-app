import 'package:linefm_radio/domain/track.dart';

/// Tolerante JSON-Parser (wie normalizeTrack der Web-App). Stub, P03.
class LautParsers {
  const LautParsers._();

  static Track? parseSong(Object? json) {
    throw UnimplementedError('P03: LautParsers.parseSong');
  }

  static List<Track> parseSongList(Object? json) {
    throw UnimplementedError('P03: LautParsers.parseSongList');
  }

  static DateTime? parseTime(Object? value) {
    throw UnimplementedError('P03: LautParsers.parseTime');
  }
}
