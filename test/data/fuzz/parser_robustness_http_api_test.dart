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
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linefm_radio/data/api/http_cache.dart';
import 'package:linefm_radio/data/api/laut_api.dart';

import '../../support/test_doubles.dart';
import 'parser_robustness_helpers.dart';
import 'random_input.dart';

void main() {
  group('HttpLautApi mit beliebigen Antworten', () {
    test('liefert Ergebnis oder LautApiException, nichts anderes', () async {
      final gen = RandomInput(seed + 30, keys: lautKeys);
      final seeds = fixtures('test/fixtures/laut');
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
          'schedule': () => api.schedule('linefm'),
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
