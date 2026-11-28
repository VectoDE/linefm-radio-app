import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'random_input.dart';

/// Fester Seed; mit `--dart-define=FUZZ_SEED=<n>` laesst sich lokal ein
/// anderer Lauf erzeugen, die CI nutzt immer diesen Wert.
const int seed = int.fromEnvironment('FUZZ_SEED', defaultValue: 20261121);

/// Durchlaeufe je synchroner Eigenschaft (lokal per FUZZ_RUNS erhoehbar).
/// Quelle: Umgebungsvariable FUZZ_RUNS (CI), sonst --dart-define, sonst 2000.
final int runs =
    int.tryParse(Platform.environment['FUZZ_RUNS'] ?? '') ??
    const int.fromEnvironment('FUZZ_RUNS', defaultValue: 2000);

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
  'day',
  'hour',
  'end_time',
  'description',
  'color',
  'shuffled',
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

bool isHttpUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null && (uri.isScheme('https') || uri.isScheme('http'));
}

/// Fuehrt [body] aus und meldet eine Exception mit Seed, Durchlauf und
/// Eingabe, damit der Fall reproduzierbar ist.
T noThrow<T>(String what, int run, Object? input, T Function() body) {
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
List<String> fixtures(String dir) => <String>[
  for (final f in Directory(dir).listSync())
    if (f is File && f.path.endsWith('.json')) f.readAsStringSync(),
];
