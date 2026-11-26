import 'dart:convert';

import 'package:linefm_radio/domain/schedule_slot.dart';
import 'package:linefm_radio/domain/track.dart';

/// Ergebnis eines geparsten laut.fm-Songs inklusive der Live-Kennung.
///
/// `live: true` setzt laut.fm, wenn der Sender gerade von einer externen
/// Live-Einspeisung (Encoder/Relay) statt aus der laut.fm-Playlist laeuft
/// (der Sender steht dann auch in `GET /stations/live`). In diesem Modus
/// kennt laut.fm die Songlaenge nicht: `id` ist ein Platzhalter, `album`,
/// `length` und `genre` fehlen, und `ends_at` des laufenden Songs ist immer
/// `started_at + 60 s`. Erst wenn der naechste Titel kommt, wird `ends_at`
/// des Vorgaengers korrigiert (gemessen am 18.11.2026 bei linefm und
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

  /// Nur bei WebSocket-Nachrichten gesetzt.
  final String? stationSlug;

  /// Laenge in Sekunden (fehlt bei Live-Sendungen).
  final int? length;
}

/// Tolerante JSON-Parser (Verhalten wie `normalizeTrack` der Web-App).
///
/// Kaputte oder leere Felder ergeben `null` statt einer Exception.
class LautParsers {
  const LautParsers._();

  /// Platzhalterdauer, die laut.fm bei Live-Sendungen fuer `ends_at` setzt.
  static const Duration livePlaceholderLength = Duration(seconds: 60);

  static final RegExp _lautTime = RegExp(
    r'^(\d{4})-(\d{1,2})-(\d{1,2})[ T](\d{1,2}):(\d{2})(?::(\d{2}))?'
    r'\s*([+-])(\d{2}):?(\d{2})$',
  );

  /// Song-Objekt -> [Track]. `null`, wenn weder Kuenstler noch Titel da sind.
  static Track? parseSong(Object? json) => parseSongDetail(json)?.track;

  /// Wie [parseSong], liefert zusaetzlich Live-Kennung, Laenge und Sender.
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
      // Platzhalter, kein echtes Songende.
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

  /// Liste von Songs (z. B. `last_songs`, genau 10, neueste zuerst).
  /// Unbrauchbare Eintraege werden uebersprungen.
  static List<Track> parseSongList(Object? json) {
    if (json is! List) return const <Track>[];
    return <Track>[for (final item in json) ?parseSong(item)];
  }

  /// Sendeplan (`schedule`): Liste von Bloecken. Eintraege ohne Namen,
  /// Wochentag oder gueltige Startstunde werden uebersprungen. Eine
  /// ungueltige Endstunde wird zu `null`.
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

  /// Zeit im laut.fm-Format `2026-11-18 18:00:00 +0100` oder ISO-8601.
  /// Ergebnis in lokaler Zeit; `null` bei unbekanntem Format.
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

  /// Hoererzahl (`/listeners` liefert eine nackte Ganzzahl).
  static int? parseListeners(Object? json) {
    final n = _int(json);
    return n == null || n < 0 ? null : n;
  }

  /// `stream_url` aus der Station-Antwort.
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

  /// Ein WebSocket-Frame enthaelt mehrere JSON-Dokumente, getrennt durch
  /// Zeilenumbruch (gemessen: ca. 1 Frame/s mit allen Wechseln aller
  /// laut.fm-Sender). Es werden nur Zeilen der gesuchten [slugs] geparst;
  /// alle anderen werden per Textvergleich verworfen, ohne JSON-Parsing.
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
    // jsonDecode('1e999') liefert Unendlich; toInt() wuerde dort werfen.
    if (value is num) return value.isFinite ? value.toInt() : null;
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
