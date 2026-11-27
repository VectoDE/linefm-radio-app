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

/// MockClient that also serves SHA256SUMS.txt next to every file: the line
/// holds the SHA-256 of whatever [handler] returns for that file.
MockClient checked(Future<http.Response> Function(http.Request) handler) =>
    MockClient((request) async {
      final segments = request.url.pathSegments;
      if (segments.isNotEmpty && segments.last == 'SHA256SUMS.txt') {
        return sumsFor(handler, request.url);
      }
      return handler(request);
    });

Future<http.Response> sumsFor(
  Future<http.Response> Function(http.Request) handler,
  Uri sumsUrl,
) async {
  final lines = StringBuffer();
  for (final file in <String>['stations.yaml', 'stations.json']) {
    var response = await handler(http.Request('GET', sumsUrl.resolve(file)));
    final location = response.headers['location'];
    if (response.statusCode >= 300 && location != null) {
      response = await handler(http.Request('GET', Uri.parse(location)));
    }
    lines.writeln('${sha256.convert(response.bodyBytes)}  $file');
  }
  lines.writeln('${'0' * 64}  other.txt');
  return http.Response(
    lines.toString(),
    200,
    headers: <String, String>{'content-type': 'text/plain'},
  );
}

/// Nachladen der Senderliste: Sicherheit, ETag, Rueckfall.
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

  group('parseUrl', () {
    test('nur https mit Host, ohne Zugangsdaten und fremden Port', () {
      expect(StationsUpdater.parseUrl(''), isNull);
      expect(StationsUpdater.parseUrl('http://app.linefm.de/s.json'), isNull);
      expect(StationsUpdater.parseUrl('https://u:p@app.linefm.de/s'), isNull);
      expect(StationsUpdater.parseUrl('https://app.linefm.de:8443/s'), isNull);
      expect(StationsUpdater.parseUrl('https://app.linefm.de/s#x'), isNull);
      expect(StationsUpdater.parseUrl('file:///etc/passwd'), isNull);
      expect(
        StationsUpdater.parseUrl(' https://app.linefm.de/stations.yaml '),
        url,
      );
    });
  });

  test('ohne Adresse kein Abruf', () async {
    var calls = 0;
    final u = StationsUpdater(
      url: null,
      prefs: InMemoryPrefsStore(),
      appVersion: '1',
      client: checked((_) async {
        calls++;
        return json(fixture);
      }),
    );
    expect(await u.refresh(), StationsUpdateOutcome.disabled);
    expect(calls, 0);
  });

  test('neue Fassung wird uebernommen und gespeichert', () async {
    final prefs = InMemoryPrefsStore();
    final u = updater(
      checked((_) async => json(withExtra(), etag: '"v2"')),
      prefs: prefs,
    );
    expect(await u.refresh(), StationsUpdateOutcome.applied);
    expect(stationsCatalog.last.slug, 'neuersender');
    expect(stationsCatalog.last.logoAsset, isNull);
    final cache =
        jsonDecode(prefs.readStationsCache()!) as Map<String, Object?>;
    expect(cache['etag'], '"v2"');

    // Naechster Start: gespeicherte Fassung sofort, ohne Netz.
    installBundledStations(parseStationsConfig(fixture));
    expect(stationBySlug('neuersender'), isNull);
    final next = updater(
      checked((_) async => throw StateError('kein Netz')),
      prefs: prefs,
    );
    expect(next.applyCached(), isTrue);
    expect(stationBySlug('neuersender'), isNotNull);
  });

  test('ETag: If-None-Match und 304 behalten die Liste', () async {
    final prefs = InMemoryPrefsStore();
    await updater(
      checked((_) async => json(withExtra(), etag: '"v2"')),
      prefs: prefs,
    ).refresh();
    String? sent;
    final u = updater(
      checked((r) async {
        sent = r.headers['If-None-Match'];
        return http.Response('', 304);
      }),
      prefs: prefs,
    )..applyCached();
    expect(await u.refresh(), StationsUpdateOutcome.notModified);
    expect(sent, '"v2"');
    expect(stationBySlug('neuersender'), isNotNull);
  });

  test('gespeicherte Fassung gilt nicht nach App-Update', () async {
    final prefs = InMemoryPrefsStore();
    await updater(
      checked((_) async => json(withExtra())),
      prefs: prefs,
    ).refresh();
    installBundledStations(parseStationsConfig(fixture));
    expect(
      updater(
        checked((_) async => json(fixture)),
        prefs: prefs,
        version: '1.1.0',
      ).applyCached(),
      isFalse,
    );
    expect(stationBySlug('neuersender'), isNull);
  });

  group('verworfen, mitgelieferte Liste bleibt', () {
    Future<void> rejects(http.Response response) async {
      final before = List.of(stationsCatalog);
      final outcome = await updater(checked((_) async => response)).refresh();
      expect(outcome, StationsUpdateOutcome.rejected);
      expect(sameStationList(stationsCatalog, before), isTrue);
    }

    test('Weiterleitung', () async {
      await rejects(
        http.Response(
          '',
          302,
          headers: <String, String>{'location': 'https://evil.example/s'},
        ),
      );
    });

    test('Fehlerstatus', () => rejects(http.Response('x', 500)));

    test('kein JSON', () async {
      await rejects(
        http.Response(
          fixture,
          200,
          headers: <String, String>{'content-type': 'text/html'},
        ),
      );
    });

    test('ungueltiges Schema', () async {
      await rejects(json(fixture.replaceFirst('#4B4B7D', 'blau')));
    });

    test('leere Liste', () async {
      await rejects(json('{"schemaVersion": 1, "sender": []}'));
    });

    test('zu gross', () async {
      await rejects(json(' ' * (stationsConfigMaxBytes + 10)));
    });
  });

  test('Netzfehler: Liste bleibt, kein Absturz', () async {
    final before = List.of(stationsCatalog);
    final outcome = await updater(
      checked((_) async => throw const SocketException('offline')),
    ).refresh();
    expect(outcome, StationsUpdateOutcome.failed);
    expect(sameStationList(stationsCatalog, before), isTrue);
  });

  test('readLimited bricht bei zu vielen Bytes ab', () async {
    final stream = Stream<List<int>>.fromIterable(<List<int>>[
      List<int>.filled(10, 1),
      List<int>.filled(10, 1),
    ]);
    expect(await StationsUpdater.readLimited(stream, 15), isNull);
  });
  group('GitHub release download', () {
    final release = Uri.parse(
      'https://github.com/VectoDE/linefm-radio-app/releases/latest/download/stations.json',
    );
    const assetUrl =
        'https://release-assets.githubusercontent.com/github-production-release-asset/1/stations.json?sig=x';

    StationsUpdater releaseUpdater(http.Client client) => StationsUpdater(
      url: release,
      prefs: InMemoryPrefsStore(),
      appVersion: '1.0.0',
      client: client,
      conditionalHeaders: true,
    );

    http.Response redirect(String location) =>
        http.Response('', 302, headers: <String, String>{'location': location});

    test('follows exactly one hop to the release asset host', () async {
      final requested = <Uri>[];
      final outcome = await releaseUpdater(
        checked((r) async {
          requested.add(r.url);
          if (r.url.host == 'github.com') return redirect(assetUrl);
          return http.Response.bytes(
            utf8.encode(withExtra()),
            200,
            headers: <String, String>{
              'content-type': 'application/octet-stream',
            },
          );
        }),
      ).refresh();
      expect(outcome, StationsUpdateOutcome.applied);
      expect(requested.take(2), <Uri>[release, Uri.parse(assetUrl)]);
      expect(stationBySlug('neuersender'), isNotNull);
    });

    test('a second redirect is rejected', () async {
      var calls = 0;
      final outcome = await releaseUpdater(
        checked((r) async {
          calls++;
          return redirect(assetUrl);
        }),
      ).refresh();
      expect(outcome, StationsUpdateOutcome.rejected);
      expect(calls, 2);
    });

    test('redirect to any other host is rejected without a request', () async {
      for (final location in <String>[
        'https://evil.example/stations.json',
        'http://release-assets.githubusercontent.com/s.json',
        'https://u:p@release-assets.githubusercontent.com/s.json',
        'https://release-assets.githubusercontent.com:8443/s.json',
        'https://githubusercontent.com.evil.example/s.json',
      ]) {
        var calls = 0;
        final outcome = await releaseUpdater(
          checked((r) async {
            calls++;
            return redirect(location);
          }),
        ).refresh();
        expect(outcome, StationsUpdateOutcome.rejected, reason: location);
        expect(calls, 1, reason: location);
      }
    });

    test('only github.com may redirect', () {
      expect(
        StationsUpdater.releaseRedirectTarget(redirect(assetUrl), url),
        isNull,
      );
      expect(
        StationsUpdater.releaseRedirectTarget(redirect(assetUrl), release),
        Uri.parse(assetUrl),
      );
    });

    test('octet-stream only from the release asset host', () {
      final binary = http.Response(
        fixture,
        200,
        headers: <String, String>{'content-type': 'application/octet-stream'},
      );
      expect(StationsUpdater.rejectReason(binary, release), isNotNull);
      expect(
        StationsUpdater.rejectReason(
          binary,
          release,
          requested: Uri.parse(assetUrl),
        ),
        isNull,
      );
      expect(
        StationsUpdater.rejectReason(
          binary,
          url,
          requested: Uri.parse(assetUrl),
        ),
        isNotNull,
      );
    });
  });
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
