import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linefm_radio/data/config/stations_source.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/stations_config.dart';

/// Nachladen der Senderliste (Issue #91): Sicherheit, ETag, Rueckfall.
void main() {
  final fixture = File('test/fixtures/stations/stations_6.json')
      .readAsStringSync();
  final url = Uri.parse('https://app.linefm.de/stations.json');

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
        StationsUpdater.parseUrl(' https://app.linefm.de/stations.json '),
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
      client: MockClient((_) async {
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
      MockClient((_) async => json(withExtra(), etag: '"v2"')),
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
      MockClient((_) async => throw StateError('kein Netz')),
      prefs: prefs,
    );
    expect(next.applyCached(), isTrue);
    expect(stationBySlug('neuersender'), isNotNull);
  });

  test('ETag: If-None-Match und 304 behalten die Liste', () async {
    final prefs = InMemoryPrefsStore();
    await updater(
      MockClient((_) async => json(withExtra(), etag: '"v2"')),
      prefs: prefs,
    ).refresh();
    String? sent;
    final u = updater(
      MockClient((r) async {
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
      MockClient((_) async => json(withExtra())),
      prefs: prefs,
    ).refresh();
    installBundledStations(parseStationsConfig(fixture));
    expect(
      updater(
        MockClient((_) async => json(fixture)),
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
      final outcome = await updater(MockClient((_) async => response))
          .refresh();
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
      MockClient((_) async => throw const SocketException('offline')),
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
}
