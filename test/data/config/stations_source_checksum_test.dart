import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linefm_radio/data/config/stations_source.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/stations_config.dart';

import '../../support/in_memory_prefs_store.dart';

void main() {
  final fixture = File('test/fixtures/stations/stations_6.json')
      .readAsStringSync();
  final url = Uri.parse('https://app.linefm.de/stations.yaml');

  setUp(() => installBundledStations(parseStationsConfig(fixture)));

  String withExtra() {
    final data = jsonDecode(fixture) as Map<String, Object?>;
    (data['sender']! as List<Object?>).add(<String, Object?>{
      'kuerzel': 'neuersender',
      'name': 'Neuer Sender',
      'farbe': '#123456',
      'logo': 'https://cdn.linefm.de/images/icons/neu.png',
    });
    return jsonEncode(data);
  }

  StationsUpdater updater(
    http.Client client, {
    PrefsStore? prefs,
    String version = '1.0.0',
  }) => StationsUpdater(
    url: url,
    prefs: prefs ?? InMemoryPrefsStore(),
    appVersion: version,
    client: client,
    conditionalHeaders: true,
  );

  http.Response json(String body, {int status = 200, String? etag}) =>
      http.Response.bytes(
        utf8.encode(body),
        status,
        headers: <String, String>{
          'content-type': 'application/json; charset=utf-8',
          'etag': ?etag,
        },
      );
  group('checksum', () {
    final body = withExtra;
    http.Response sums(String text, {int status = 200}) => http.Response(
      text,
      status,
      headers: <String, String>{'content-type': 'text/plain'},
    );

    Future<StationsUpdateOutcome> run(http.Response Function() sumsResponse) {
      return updater(
        MockClient((r) async {
          if (r.url.path.endsWith('/SHA256SUMS.txt')) return sumsResponse();
          return json(body());
        }),
      ).refresh();
    }

    test('URL of the checksum list', () {
      expect(
        StationsUpdater.checksumsUrl(url).toString(),
        'https://app.linefm.de/SHA256SUMS.txt',
      );
      expect(
        StationsUpdater.checksumsUrl(
          Uri.parse(
            'https://github.com/o/r/releases/latest/download/stations.json',
          ),
        ).toString(),
        'https://github.com/o/r/releases/latest/download/SHA256SUMS.txt',
      );
    });

    test('match: applied', () async {
      final hash = sha256.convert(utf8.encode(body()));
      expect(
        await run(() => sums('$hash *stations.yaml\n')),
        StationsUpdateOutcome.applied,
      );
    });

    for (final (name, response) in <(String, http.Response Function())>[
      ('mismatch', () => sums('${'a' * 64}  stations.yaml\n')),
      ('no line for the file', () => sums('${'a' * 64}  other.yaml\n')),
      ('checksum list missing', () => sums('not found', status: 404)),
      (
        'checksum list too big',
        () => sums('x' * (StationsUpdater.checksumsMaxBytes + 1)),
      ),
    ]) {
      test('$name: rejected, bundled list stays', () async {
        final before = List.of(stationsCatalog);
        expect(await run(response), StationsUpdateOutcome.rejected);
        expect(sameStationList(stationsCatalog, before), isTrue);
        expect(stationBySlug('neuersender'), isNull);
      });
    }

    test('release: checksum list also via the one redirect', () async {
      const asset = 'https://release-assets.githubusercontent.com/x/';
      final release = Uri.parse(
        'https://github.com/o/r/releases/latest/download/stations.json',
      );
      final hash = sha256.convert(utf8.encode(body()));
      final seen = <String>[];
      final outcome = await StationsUpdater(
        url: release,
        prefs: InMemoryPrefsStore(),
        appVersion: '1.0.0',
        client: MockClient((r) async {
          seen.add(r.url.toString());
          final file = r.url.pathSegments.last;
          if (r.url.host == 'github.com') {
            return http.Response(
              '',
              302,
              headers: <String, String>{'location': '$asset$file'},
            );
          }
          return http.Response.bytes(
            utf8.encode(
              file == 'SHA256SUMS.txt' ? '$hash  stations.json\n' : body(),
            ),
            200,
            headers: <String, String>{
              'content-type': 'application/octet-stream',
            },
          );
        }),
      ).refresh();
      expect(outcome, StationsUpdateOutcome.applied);
      expect(seen, hasLength(4));
    });

    test('expectedChecksum parses sha256sum output', () {
      final h = 'A' * 64;
      expect(
        StationsUpdater.expectedChecksum('$h  s.json', 's.json'),
        'a' * 64,
      );
      expect(
        StationsUpdater.expectedChecksum('$h *s.json\r\n', 's.json'),
        'a' * 64,
      );
      expect(StationsUpdater.expectedChecksum('abc  s.json', 's.json'), isNull);
      expect(StationsUpdater.expectedChecksum('$h  s.json', ''), isNull);
    });
  });
}
