import 'dart:convert';

import 'package:linefm_radio/domain/schedule_slot.dart';
import 'package:linefm_radio/domain/track.dart';

/// Result of a parsed laut.fm song including the live flag.
///
/// laut.fm sets `live: true` when the station is currently fed by an external
/// live source (encoder/relay) instead of the laut.fm playlist
/// (the station then also appears in `GET /stations/live`). In this mode
/// laut.fm does not know the song length: `id` is a placeholder, `album`,
/// `length` and `genre` are missing, and `ends_at` of the running song is always
/// `started_at + 60 s`. Only when the next track arrives is `ends_at`
/// of the predecessor corrected (measured on 2026-11-18 for linefm and
/// linefmgaming).
class LautSong {
  const LautSong({
    required this.track,
    this.isLive = false,
    this.stationSlug,
    this.length,
  });

  final Track track;
  final bool isLive;

  /// Only set for WebSocket messages.
  final String? stationSlug;

  /// Length in seconds (missing for live shows).
  final int? length;
}

/// Tolerant JSON parsers (behaviour like `normalizeTrack` of the web app).
///
/// Broken or empty fields yield `null` instead of an exception.
class LautParsers {
  const LautParsers._();

  /// Placeholder duration laut.fm uses for `ends_at` on live shows.
  static const Duration livePlaceholderLength = Duration(seconds: 60);

  static final RegExp _lautTime = RegExp(
    r'^(\d{4})-(\d{1,2})-(\d{1,2})[ T](\d{1,2}):(\d{2})(?::(\d{2}))?'
    r'\s*([+-])(\d{2}):?(\d{2})$',
  );

  /// Song object -> [Track]. `null` if neither artist nor title is present.
  static Track? parseSong(Object? json) => parseSongDetail(json)?.track;

  /// Like [parseSong], additionally returns live flag, length and station.
  static LautSong? parseSongDetail(Object? json) {
    if (json is! Map) return null;
    final artist = _artistOf(json);
    final title = _firstString(json, const ['title', 'track', 'name']) ?? '';
    if (artist.isEmpty && title.isEmpty) return null;

    final isLive = json['live'] == true;
    final startedAt = parseTime(json['started_at']);
    var endsAt = parseTime(json['ends_at']);
    if (isLive &&
        startedAt != null &&
        endsAt != null &&
        endsAt.difference(startedAt) == livePlaceholderLength) {
      // Placeholder, not a real song end.
      endsAt = null;
    }

    final album = _string(json['album']);
    final station = json['station'];
    return LautSong(
      track: Track(
        artist: artist,
        title: title,
        album: album == null || album.isEmpty ? null : album,
        artworkUrl: _artworkOf(json),
        startedAt: startedAt,
        endsAt: endsAt,
      ),
      isLive: isLive,
      stationSlug: station is String
          ? station
          : (station is Map ? _string(station['name']) : null),
      length: _int(json['length']),
    );
  }

  /// List of songs (e.g. `last_songs`, exactly 10, newest first).
  /// Unusable entries are skipped.
  static List<Track> parseSongList(Object? json) {
    if (json is! List) return const <Track>[];
    return <Track>[for (final item in json) ?parseSong(item)];
  }

  /// Schedule (`schedule`): list of blocks. Entries without a name,
  /// weekday or valid start hour are skipped. An
  /// invalid end hour becomes `null`.
  static List<ScheduleSlot> parseSchedule(Object? json) {
    if (json is! List) return const <ScheduleSlot>[];
    return <ScheduleSlot>[for (final item in json) ?_parseSlot(item)];
  }

  static ScheduleSlot? _parseSlot(Object? json) {
    if (json is! Map) return null;
    final name = _string(json['name']);
    final day = ScheduleDay.tryParse(json['day']);
    final start = _int(json['hour']);
    if (name == null || name.isEmpty || day == null) return null;
    if (start == null || start < 0 || start > 23) return null;
    final end = _int(json['end_time']);
    final description = _string(json['description']);
    final color = _string(json['color']);
    final shuffled = json['shuffled'];
    return ScheduleSlot(
      id: _int(json['id']),
      name: name,
      day: day,
      startHour: start,
      endHour: end != null && end >= 0 && end <= 24 ? end : null,
      description: description == null || description.isEmpty
          ? null
          : description,
      colorHex: color != null && _hexColor.hasMatch(color) ? color : null,
      shuffled: shuffled is bool ? shuffled : null,
    );
  }

  static final RegExp _hexColor = RegExp(r'^#[0-9a-fA-F]{6}$');

  /// Time in laut.fm format `2026-11-18 18:00:00 +0100` or ISO-8601.
  /// Result in local time; `null` for an unknown format.
  static DateTime? parseTime(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    final m = _lautTime.firstMatch(text);
    if (m != null) {
      final utc = DateTime.utc(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
        int.parse(m.group(6) ?? '0'),
      );
      final offset = Duration(
        hours: int.parse(m.group(8)!),
        minutes: int.parse(m.group(9)!),
      );
      final shifted = m.group(7) == '+'
          ? utc.subtract(offset)
          : utc.add(offset);
      return shifted.toLocal();
    }
    return DateTime.tryParse(text)?.toLocal();
  }

  /// Listener count (`/listeners` returns a bare integer).
  static int? parseListeners(Object? json) {
    final n = _int(json);
    return n == null || n < 0 ? null : n;
  }

  /// `stream_url` from the station response.
  static String? parseStreamUrl(Object? json) {
    if (json is! Map) return null;
    final url = _string(json['stream_url']);
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      return null;
    }
    return url;
  }

  /// A WebSocket frame contains several JSON documents separated by
  /// newlines (measured: about 1 frame/s with all changes of all
  /// laut.fm stations). Only lines of the requested [slugs] are parsed;
  /// all others are discarded by text comparison, without JSON parsing.
  static List<LautSong> parseSongChangeFrame(String frame, Set<String> slugs) {
    final result = <LautSong>[];
    for (final line in const LineSplitter().convert(frame)) {
      if (line.isEmpty || !_mentionsAny(line, slugs)) continue;
      final Object? json;
      try {
        json = jsonDecode(line);
      } on FormatException {
        continue;
      }
      final song = parseSongDetail(json);
      if (song == null) continue;
      final slug = song.stationSlug;
      if (slug != null && slugs.contains(slug)) result.add(song);
    }
    return result;
  }

  static bool _mentionsAny(String line, Set<String> slugs) {
    for (final slug in slugs) {
      if (line.contains('"$slug"')) return true;
    }
    return false;
  }

  static String _artistOf(Map<Object?, Object?> json) {
    final raw = json['artist'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw is Map) {
      final name = _string(raw['name']);
      if (name != null && name.isNotEmpty) return name;
    }
    return _firstString(json, const ['artist_name', 'performer']) ?? '';
  }

  static String? _artworkOf(Map<Object?, Object?> json) {
    final cover = json['cover'];
    if (cover is Map) {
      final url = _httpUrl(cover['url']);
      if (url != null) return url;
    }
    for (final key in const ['cover', 'artwork', 'image', 'album_image']) {
      final url = _httpUrl(json[key]);
      if (url != null) return url;
    }
    return null;
  }

  static String? _httpUrl(Object? value) {
    final text = _string(value);
    if (text == null) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      return null;
    }
    return text;
  }

  static String? _firstString(Map<Object?, Object?> json, List<String> keys) {
    for (final key in keys) {
      final value = _string(json[key]);
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _string(Object? value) =>
      value is String ? value.trim() : (value is num ? value.toString() : null);

  static int? _int(Object? value) {
    if (value is int) return value;
    // jsonDecode('1e999') yields infinity; toInt() would throw there.
    if (value is num) return value.isFinite ? value.toInt() : null;
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
