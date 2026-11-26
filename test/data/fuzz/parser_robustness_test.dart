// Zufallsbasierte Robustheitstests (property-based) fuer die
// Parser der laut.fm-API und der iTunes-Suche.
//
// Eigenschaft: Beliebige, auch kaputte Eingaben fuehren nie zu einer
// Exception. Einzige erlaubte Ausnahme ist der definierte Fehlertyp
// LautApiException von HttpLautApi. Die Werte stammen aus einem eigenen
// Generator (random_input.dart) mit festem Seed; ein Fehlschlag nennt Seed,
// Durchlauf und Eingabe und ist damit lokal nachstellbar.
//
// Hinweis: OpenSSF Scorecard erkennt fuer Dart keine Fuzzing-Integration.
// Diese Tests zaehlen dort nicht als Fuzzing, decken aber dieselbe Klasse
// von Fehlern ab (siehe SECURITY.md).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linefm_radio/data/api/http_cache.dart';
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/data/api/laut_parsers.dart';
import 'package:linefm_radio/data/artwork/itunes_artwork.dart';
import 'package:linefm_radio/domain/track.dart';

import '../../support/test_doubles.dart';
import 'random_input.dart';

/// Fester Seed; mit `--dart-define=FUZZ_SEED=<n>` laesst sich lokal ein
/// anderer Lauf erzeugen, die CI nutzt immer diesen Wert.
const int seed = int.fromEnvironment('FUZZ_SEED', defaultValue: 20261121);

/// Durchlaeufe je synchroner Eigenschaft (lokal per FUZZ_RUNS erhoehbar).
const int runs = int.fromEnvironment('FUZZ_RUNS', defaultValue: 2000);

const List<String> lautKeys = <String>[
  'artist',
  'title',
  'track',
  'name',
  'live',
  'started_at',
  'ends_at',
  'album',
  'station',
  'length',
  'cover',
  'url',
  'artwork',
  'image',
  'album_image',
  'artist_name',
  'performer',
  'stream_url',
  'type',
  'id',
];

const List<String> itunesKeys = <String>[
  'resultCount',
  'results',
  'artistName',
  'trackName',
  'artworkUrl100',
  'trackViewUrl',
  'kind',
  'wrapperType',
];

const List<String> slugs = <String>['linefm', 'linefmrap', 'fobfm'];

bool _isHttpUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null && (uri.isScheme('https') || uri.isScheme('http'));
}

/// Fuehrt [body] aus und meldet eine Exception mit Seed, Durchlauf und
/// Eingabe, damit der Fall reproduzierbar ist.
T _noThrow<T>(String what, int run, Object? input, T Function() body) {
  try {
    return body();
  } on Object catch (e) {
    fail(
      '$what warf ${e.runtimeType} (Seed $seed, Durchlauf $run): $e\n'
      'Eingabe: ${describe(input)}',
    );
  }
}

/// Echte Antworten aus test/fixtures als Ausgangspunkt fuer Mutationen.
List<String> _fixtures(String dir) => <String>[
  for (final f in Directory(dir).listSync())
    if (f is File && f.path.endsWith('.json')) f.readAsStringSync(),
];

void main() {
  group('LautParsers mit beliebigen Werten', () {
    test('parseSongDetail, parseSong, parseSongList werfen nie', () {
      final gen = RandomInput(seed, keys: lautKeys);
      for (var run = 0; run < runs; run++) {
        final input = gen.chance(0.3)
            ? <Object?>[for (var i = gen.nextInt(12); i > 0; i--) gen.map()]
            : (gen.chance(0.8) ? gen.map() : gen.value());
        final song = _noThrow(
          'parseSongDetail',
          run,
          input,
          () => LautParsers.parseSongDetail(input),
        );
        if (song != null) {
          final t = song.track;
          expect(t.artist.isNotEmpty || t.title.isNotEmpty, isTrue);
          final art = t.artworkUrl;
          if (art != null) expect(_isHttpUrl(art), isTrue, reason: art);
        }
        _noThrow('parseSong', run, input, () => LautParsers.parseSong(input));
        _noThrow(
          'parseSongList',
          run,
          input,
          () => LautParsers.parseSongList(input),
        );
      }
    });

    test('parseTime wirft nie', () {
      final gen = RandomInput(seed + 1);
      for (var run = 0; run < runs; run++) {
        final Object? input = gen.chance(0.9) ? gen.string() : gen.value();
        _noThrow('parseTime', run, input, () => LautParsers.parseTime(input));
      }
    });

    test('parseListeners: null oder >= 0, wirft nie', () {
      final gen = RandomInput(seed + 2);
      for (var run = 0; run < runs; run++) {
        final input = gen.chance(0.5) ? gen.number() : gen.value();
        final n = _noThrow(
          'parseListeners',
          run,
          input,
          () => LautParsers.parseListeners(input),
        );
        if (n != null) expect(n, greaterThanOrEqualTo(0));
      }
    });

    test('parseStreamUrl: null oder http(s), wirft nie', () {
      final gen = RandomInput(seed + 3, keys: lautKeys);
      for (var run = 0; run < runs; run++) {
        final input = gen.chance(0.8) ? gen.map() : gen.value();
        final url = _noThrow(
          'parseStreamUrl',
          run,
          input,
          () => LautParsers.parseStreamUrl(input),
        );
        if (url != null) expect(_isHttpUrl(url), isTrue, reason: url);
      }
    });

    test('Zahlen aus jsonDecode (1e999 = Unendlich) werfen nie', () {
      // jsonDecode('1e999') liefert double.infinity; toInt() darauf wirft.
      for (final text in <String>[
        '1e999',
        '-1e999',
        '{"artist":"A","title":"T","length":1e999}',
        '{"artist":"A","title":"T","length":-1e999}',
        '{"artist":1e999,"title":1e999}',
      ]) {
        final json = jsonDecode(text);
        _noThrow('parseListeners', 0, text, () {
          expect(LautParsers.parseListeners(json), isNull);
        });
        _noThrow('parseSongDetail', 0, text, () {
          LautParsers.parseSongDetail(json);
        });
      }
    });

    test('Track.tryFromJson wirft nie', () {
      final gen = RandomInput(
        seed + 4,
        keys: const <String>[
          'artist',
          'title',
          'album',
          'artworkUrl',
          'startedAt',
          'endsAt',
        ],
      );
      for (var run = 0; run < runs; run++) {
        final input = gen.chance(0.8) ? gen.map() : gen.value();
        _noThrow('Track.tryFromJson', run, input, () {
          Track.tryFromJson(input);
        });
      }
    });
  });

  group('LautParsers mit beliebigen Texten', () {
    test('parseSongChangeFrame wirft nie und filtert nach Sender', () {
      final gen = RandomInput(seed + 10, keys: <String>[...lautKeys, ...slugs]);
      final seeds = _fixtures('test/fixtures/laut');
      for (var run = 0; run < runs; run++) {
        final lines = <String>[
          for (var i = 1 + gen.nextInt(6); i > 0; i--)
            switch (gen.nextInt(3)) {
              0 => gen.jsonText(),
              1 => gen.mutate(
                jsonEncode(<String, Object?>{
                  ...gen.map(finite: true),
                  'station': <String, Object?>{'name': gen.pick(slugs)},
                }),
              ),
              _ => gen.mutate(gen.pick(seeds).replaceAll('\n', ' ')),
            },
        ];
        final frame = lines.join(gen.chance(0.2) ? '\r\n' : '\n');
        final wanted = <String>{gen.pick(slugs), if (gen.chance(0.3)) 'x"'};
        final songs = _noThrow(
          'parseSongChangeFrame',
          run,
          frame,
          () => LautParsers.parseSongChangeFrame(frame, wanted),
        );
        for (final s in songs) {
          expect(wanted, contains(s.stationSlug));
        }
      }
    });
  });

  group('iTunes mit beliebigen Eingaben', () {
    test('parseSearch wirft nie, Links nur https', () {
      final gen = RandomInput(seed + 20, keys: itunesKeys);
      final seeds = _fixtures('test/fixtures/itunes');
      for (var run = 0; run < runs; run++) {
        final String body = switch (gen.nextInt(4)) {
          0 => gen.jsonText(),
          1 => gen.mutate(gen.pick(seeds)),
          2 => jsonEncode(<String, Object?>{
            'resultCount': gen.nextInt(10),
            'results': <Object?>[
              for (var i = gen.nextInt(6); i > 0; i--) gen.map(finite: true),
            ],
          }),
          _ => gen.string(),
        };
        final track = gen.chance(0.2)
            ? null
            : Track(artist: gen.string(), title: gen.string());
        final r = _noThrow(
          'parseSearch',
          run,
          body,
          () => ItunesArtworkService.parseSearch(body, track: track),
        );
        if (r != null) {
          final a = r.artworkUrl;
          final v = r.trackViewUrl;
          expect(a != null || v != null, isTrue);
          if (a != null) expect(a, startsWith('https://'));
          if (v != null) expect(v, startsWith('https://'));
        }
      }
    });

    test('normalize und matchesTrack werfen nie', () {
      final gen = RandomInput(seed + 21);
      for (var run = 0; run < runs; run++) {
        final a = gen.string();
        final t = gen.string();
        final ia = gen.string();
        final it = gen.string();
        _noThrow('normalize', run, a, () => ItunesArtworkService.normalize(a));
        _noThrow('matchesTrack', run, '$a | $t | $ia | $it', () {
          ItunesArtworkService.matchesTrack(
            Track(artist: a, title: t),
            artist: ia,
            title: it,
          );
        });
      }
    });

    test('ArtworkResult.fromJson wirft nie', () {
      final gen = RandomInput(seed + 22, keys: const <String>['a', 'v']);
      for (var run = 0; run < runs; run++) {
        final input = gen.chance(0.8) ? gen.map() : gen.value();
        _noThrow('ArtworkResult.fromJson', run, input, () {
          ArtworkResult.fromJson(input);
        });
      }
    });

    test('kaputter Cover-Cache im Speicher wirft beim Laden nie', () async {
      final gen = RandomInput(
        seed + 23,
        keys: const <String>['v', 'e', 'x', 'r', 'a', 'v'],
      );
      final clock = FakeClock(DateTime.utc(2026, 11, 18, 20));
      final client = MockClient((_) async => http.Response('{}', 200));
      for (var run = 0; run < runs ~/ 4; run++) {
        final String text = switch (gen.nextInt(4)) {
          0 => gen.jsonText(),
          1 => jsonEncode(<String, Object?>{
            'v': 2,
            'e': <String, Object?>{
              for (var i = gen.nextInt(4); i > 0; i--)
                gen.string(): <String, Object?>{
                  'x': gen.chance(0.5)
                      ? gen.pick(<int>[
                          8640000000000001,
                          -8640000000000001,
                          9223372036854775807,
                          DateTime.utc(2027).millisecondsSinceEpoch,
                        ])
                      : gen.value(finite: true),
                  'r': gen.value(finite: true),
                },
            },
          }),
          2 => '{"v":2,"e":{"k":{"x":1e999}}}',
          _ => gen.string(),
        };
        final service = _noThrow(
          'ItunesArtworkService(store)',
          run,
          text,
          () => ItunesArtworkService(
            client: client,
            clock: clock,
            sleep: (_) async {},
            store: CoverCacheStore(read: () => text, write: (_) async {}),
          ),
        );
        await service.flush();
      }
    });
  });

  group('HttpLautApi mit beliebigen Antworten', () {
    test('liefert Ergebnis oder LautApiException, nichts anderes', () async {
      final gen = RandomInput(seed + 30, keys: lautKeys);
      final seeds = _fixtures('test/fixtures/laut');
      for (var run = 0; run < runs ~/ 10; run++) {
        final Uint8List bytes = switch (gen.nextInt(4)) {
          0 => Uint8List.fromList(utf8.encode(gen.jsonText())),
          1 => Uint8List.fromList(utf8.encode(gen.mutate(gen.pick(seeds)))),
          2 => Uint8List.fromList(<int>[
            for (var i = gen.nextInt(64); i > 0; i--) gen.nextInt(256),
          ]),
          _ => Uint8List.fromList(
            utf8.encode(jsonEncode(gen.map(finite: true))),
          ),
        };
        final status = gen.chance(0.85)
            ? 200
            : gen.pick(<int>[204, 304, 404, 429, 500]);
        final api = HttpLautApi(
          cache: HttpCache(
            client: MockClient((_) async => http.Response.bytes(bytes, status)),
            clock: FakeClock(DateTime.utc(2026, 11, 18, 20)),
          ),
        );
        final calls = <String, Future<Object?> Function()>{
          'currentSongDetail': () => api.currentSongDetail('linefm'),
          'lastSongs': () => api.lastSongs('linefm'),
          'listeners': () => api.listeners('linefm'),
          'streamUrl': () => api.streamUrl('linefm'),
        };
        for (final MapEntry(:key, :value) in calls.entries) {
          try {
            await value();
          } on LautApiException {
            // definierter Fehlertyp
          } on Object catch (e) {
            fail(
              '$key warf ${e.runtimeType} (Seed $seed, Durchlauf $run, '
              'Status $status): $e\nEingabe: ${describe(bytes)}',
            );
          }
        }
        api.close();
      }
    });
  });
}
