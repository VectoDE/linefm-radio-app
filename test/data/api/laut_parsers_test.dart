import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/data/api/laut_parsers.dart';

const _slugs = <String>[
  'linefm',
  'linefmrap',
  'linefmgaming',
  'linefmlofi',
  'radio3fm',
  'fobfm',
];

Object? _fixture(String name) =>
    jsonDecode(File('test/fixtures/laut/$name').readAsStringSync());

void main() {
  group('parseTime', () {
    test('laut.fm-Format mit Offset', () {
      final t = LautParsers.parseTime('2026-11-18 21:07:16 +0100')!;
      expect(t.toUtc(), DateTime.utc(2026, 11, 18, 20, 7, 16));
      expect(t.isUtc, isFalse);
    });

    test('laut.fm-Format mit negativem Offset und Doppelpunkt', () {
      final t = LautParsers.parseTime('2026-03-29 01:59:59 -05:30')!;
      expect(t.toUtc(), DateTime.utc(2026, 3, 29, 7, 29, 59));
    });

    test('ISO-8601 mit Z und mit Offset', () {
      expect(
        LautParsers.parseTime('2026-11-18T20:07:16Z')!.toUtc(),
        DateTime.utc(2026, 11, 18, 20, 7, 16),
      );
      expect(
        LautParsers.parseTime('2026-11-18T21:07:16+01:00')!.toUtc(),
        DateTime.utc(2026, 11, 18, 20, 7, 16),
      );
    });

    test('unbrauchbare Werte -> null', () {
      for (final v in <Object?>[null, '', '  ', 'gestern', 42, <String>[]]) {
        expect(LautParsers.parseTime(v), isNull, reason: '$v');
      }
    });
  });

  group('parseSong mit echten Fixtures', () {
    for (final slug in _slugs) {
      test('$slug current_song', () {
        final song = LautParsers.parseSongDetail(
          _fixture('${slug}_current_song.json'),
        )!;
        expect(song.track.artist, isNotEmpty);
        expect(song.track.title, isNotEmpty);
        expect(song.track.startedAt, isNotNull);
        if (song.isLive) {
          // Live: Platzhalter-Ende (started_at + 60 s) wird verworfen.
          expect(song.track.endsAt, isNull);
          expect(song.track.album, isNull);
        } else {
          expect(song.track.endsAt!.isAfter(song.track.startedAt!), isTrue);
        }
      });

      test('$slug last_songs liefert genau 10', () {
        final list = LautParsers.parseSongList(
          _fixture('${slug}_last_songs.json'),
        );
        expect(list, hasLength(10));
        expect(list.every((t) => t.title.isNotEmpty), isTrue);
      });

      test('$slug listeners und stream_url', () {
        expect(
          LautParsers.parseListeners(_fixture('${slug}_listeners.json')),
          isNotNull,
        );
        expect(
          LautParsers.parseStreamUrl(_fixture('$slug.json')),
          startsWith('https://$slug.stream.laut.fm/'),
        );
      });
    }

    test('linefm ist live (Fixture vom 18.11.2026)', () {
      final song = LautParsers.parseSongDetail(
        _fixture('linefm_current_song.json'),
      )!;
      expect(song.isLive, isTrue);
      expect(song.track.artist, 'Mark Ronson & Lykke Li');
      expect(song.track.title, 'Late Night Feelings');
      expect(song.length, isNull);
    });

    test('linefmrap mit Album und Laenge', () {
      final song = LautParsers.parseSongDetail(
        _fixture('linefmrap_current_song.json'),
      )!;
      expect(song.isLive, isFalse);
      expect(song.track.album, 'Miss E....So Addictive [Explicit]');
      expect(song.length, 236);
      expect(
        song.track.endsAt!.difference(song.track.startedAt!),
        const Duration(minutes: 3, seconds: 57),
      );
      // artist.image ist ein Kuenstlerfoto, kein Cover.
      expect(song.track.artworkUrl, isNull);
    });

    test('Live-Eintrag in last_songs behaelt das korrigierte Ende', () {
      final list = LautParsers.parseSongList(
        _fixture('linefm_last_songs.json'),
      );
      // Eintrag 1 ist bereits beendet und hat die echte Laenge.
      expect(list[1].endsAt, isNotNull);
    });
  });

  group('parseSong tolerant wie normalizeTrack', () {
    test('artist als String, Rueckfall artist_name/performer', () {
      expect(
        LautParsers.parseSong(<String, Object?>{'artist': 'A', 'title': 'T'})!
            .artist,
        'A',
      );
      expect(
        LautParsers.parseSong(<String, Object?>{
          'artist_name': 'B',
          'track': 'T',
        })!.artist,
        'B',
      );
      final p = LautParsers.parseSong(<String, Object?>{
        'artist': <String, Object?>{'name': ''},
        'performer': 'C',
        'name': 'N',
      })!;
      expect(p.artist, 'C');
      expect(p.title, 'N');
    });

    test('Cover-Felder in Reihenfolge der Web-App', () {
      expect(
        LautParsers.parseSong(<String, Object?>{
          'title': 'T',
          'cover': <String, Object?>{'url': 'https://x/c.jpg'},
          'image': 'https://x/i.jpg',
        })!.artworkUrl,
        'https://x/c.jpg',
      );
      expect(
        LautParsers.parseSong(<String, Object?>{
          'title': 'T',
          'album_image': 'https://x/a.jpg',
        })!.artworkUrl,
        'https://x/a.jpg',
      );
      expect(
        LautParsers.parseSong(<String, Object?>{
          'title': 'T',
          'cover': 'javascript:alert(1)',
        })!.artworkUrl,
        isNull,
      );
    });

    test('leere oder kaputte Daten -> null statt Absturz', () {
      for (final v in <Object?>[
        null,
        'x',
        42,
        <Object?>[],
        <String, Object?>{},
        <String, Object?>{'artist': 7, 'title': null},
        <String, Object?>{'title': '  ', 'artist': <String, Object?>{}},
      ]) {
        expect(LautParsers.parseSong(v), isNull, reason: '$v');
      }
      final t = LautParsers.parseSong(<String, Object?>{
        'title': 'T',
        'started_at': 'kaputt',
        'ends_at': 12,
        'album': '',
      })!;
      expect(t.startedAt, isNull);
      expect(t.endsAt, isNull);
      expect(t.album, isNull);
    });

    test('Listen ueberspringen kaputte Eintraege', () {
      expect(
        LautParsers.parseSongList(<Object?>[
          null,
          <String, Object?>{'title': 'A'},
          'x',
        ]),
        hasLength(1),
      );
      expect(LautParsers.parseSongList(<String, Object?>{}), isEmpty);
    });

    test('listeners und stream_url tolerant', () {
      expect(LautParsers.parseListeners(3), 3);
      expect(LautParsers.parseListeners('4'), 4);
      expect(LautParsers.parseListeners(-1), isNull);
      expect(LautParsers.parseListeners('x'), isNull);
      expect(
        LautParsers.parseStreamUrl(<String, Object?>{'stream_url': 'ftp://x'}),
        isNull,
      );
      expect(LautParsers.parseStreamUrl(null), isNull);
    });
  });

  group('WebSocket-Frame (JSONL)', () {
    final ours = _slugs.toSet();

    test('echter Frame ohne unsere Sender -> leer', () {
      final frame = File('test/fixtures/laut/ws_frame_sample.jsonl')
          .readAsStringSync();
      expect(frame.split('\n').where((l) => l.isNotEmpty), hasLength(3));
      expect(LautParsers.parseSongChangeFrame(frame, ours), isEmpty);
      expect(
        LautParsers.parseSongChangeFrame(frame, <String>{
          'rbsw2',
        }).single.track.artist,
        'Duo Via Mala',
      );
    });

    test('filtert auf unsere Slugs, Live-Kennung bleibt erhalten', () {
      final frame = File('test/fixtures/laut/ws_ours.jsonl')
          .readAsLinesSync()
          .map((l) => l.substring(l.indexOf(' ') + 1))
          .join('\n');
      final songs = LautParsers.parseSongChangeFrame(
        '$frame\n{"station":"linefmx","title":"X"}\nkein json "linefm"\n',
        ours,
      );
      expect(songs, hasLength(15));
      expect(songs.every((s) => ours.contains(s.stationSlug)), isTrue);
      final live = songs.where((s) => s.isLive).toList();
      expect(live.map((s) => s.stationSlug).toSet(), <String>{
        'linefm',
        'linefmgaming',
      });
      expect(live.every((s) => s.track.endsAt == null), isTrue);
    });
  });
}
