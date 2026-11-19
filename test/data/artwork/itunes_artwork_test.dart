import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/data/artwork/itunes_artwork.dart';
import 'package:linefm_radio/domain/track.dart';

final _hit = File('test/fixtures/itunes/search_hit.json').readAsStringSync();
final _empty = File('test/fixtures/itunes/search_empty.json')
    .readAsStringSync();

Track _t(String artist, String title, {String? artworkUrl}) =>
    Track(artist: artist, title: title, artworkUrl: artworkUrl);

/// Passt zum Treffer in `search_hit.json` (D8 prueft Kuenstler und Titel).
final _missy = _t('Missy Elliott', 'Get Ur Freak On');

void main() {
  late FakeClock clock;
  late List<Duration> sleeps;
  late List<(DateTime, Uri)> requests;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 11, 18, 20));
    sleeps = <Duration>[];
    requests = <(DateTime, Uri)>[];
  });

  Future<void> fakeSleep(Duration d) async {
    sleeps.add(d);
    clock.advance(d);
  }

  ItunesArtworkService service(
    FutureOr<http.Response> Function(http.Request) handler, {
    CoverCacheStore? store,
  }) => ItunesArtworkService(
    client: MockClient((r) async {
      requests.add((clock.now(), r.url));
      return handler(r);
    }),
    clock: clock,
    sleep: fakeSleep,
    store: store,
    persistDelay: Duration.zero,
  );

  test('100x100 -> 600x600 und Apple-Music-Link', () async {
    final s = service((_) => http.Response(_hit, 200));
    final r = await s.lookup(_t('Missy Elliott', 'Get Ur Freak On'));
    expect(
      r!.artworkUrl,
      'https://is1-ssl.mzstatic.com/image/thumb/Music/71/c2/4f/'
      'mzi.gsutnxrb.jpg/600x600bb.jpg',
    );
    expect(r.trackViewUrl, startsWith('https://music.apple.com/de/album/'));
    final q = requests.single.$2.queryParameters;
    expect(q['term'], 'Missy Elliott Get Ur Freak On');
    expect(q['entity'], 'song');
    expect(q['limit'], '5');
    expect(q['country'], 'DE');
  });

  test('Cache: zweiter Aufruf ohne Anfrage, Schluessel lowercase', () async {
    final s = service((_) => http.Response(_hit, 200));
    await s.lookup(_t('Missy Elliott', 'Get Ur Freak On'));
    final again = await s.lookup(_t('MISSY ELLIOTT', 'get ur freak on'));
    expect(again!.artworkUrl, endsWith('600x600bb.jpg'));
    expect(requests, hasLength(1));
  });

  test('Negativ-Cache 1 Tag, danach neuer Versuch', () async {
    final s = service((_) => http.Response(_empty, 200));
    expect(await s.lookup(_t('A', 'B')), isNull);
    clock.advance(const Duration(hours: 23));
    expect(await s.lookup(_t('A', 'B')), isNull);
    expect(requests, hasLength(1));
    clock.advance(const Duration(hours: 2));
    await s.lookup(_t('A', 'B'));
    expect(requests, hasLength(2));
  });

  test('Positiv-Cache laeuft nach 30 Tagen ab', () async {
    final s = service((_) => http.Response(_hit, 200));
    expect(await s.lookup(_missy), isNotNull);
    clock.advance(const Duration(days: 29));
    await s.lookup(_missy);
    expect(requests, hasLength(1));
    clock.advance(const Duration(days: 2));
    await s.lookup(_missy);
    expect(requests, hasLength(2));
  });

  test('API-Cover hat Vorrang, keine Anfrage', () async {
    final s = service((_) => http.Response(_hit, 200));
    final r = await s.lookup(
      _t('A', 'B', artworkUrl: 'https://assets.laut.fm/x.jpg'),
    );
    expect(r!.artworkUrl, 'https://assets.laut.fm/x.jpg');
    expect(requests, isEmpty);
  });

  test('Drosselung: mind. 1,5 s zwischen Anfragestarts (Fake-Uhr)', () async {
    final s = service((_) => http.Response(_hit, 200));
    final start = clock.now();
    await Future.wait(<Future<ArtworkResult?>>[
      for (var i = 0; i < 4; i++) s.lookup(_t('A$i', 'T')),
    ]);
    expect(requests, hasLength(4));
    // 4 Starts brauchen mind. 3 Abstaende a 1,5 s Fake-Zeit.
    expect(
      clock.now().difference(start),
      greaterThanOrEqualTo(const Duration(milliseconds: 4500)),
    );
    expect(sleeps.every((d) => d <= const Duration(milliseconds: 1500)), true);
    expect(sleeps, isNotEmpty);
  });

  test('Prioritaet: aktiver Titel vor Verlauf', () async {
    final gate = Completer<void>();
    final s = service((r) async {
      if (requests.length == 1) await gate.future;
      return http.Response(_hit, 200);
    });
    final first = s.lookup(_t('Erster', 'T'));
    // Warten, bis die erste Anfrage laeuft.
    await Future<void>.delayed(Duration.zero);
    final history = <Future<ArtworkResult?>>[
      for (var i = 0; i < 3; i++) s.lookup(_t('Verlauf$i', 'T')),
    ];
    final active = s.lookup(_t('Aktiv', 'T'), priority: true);
    gate.complete();
    await Future.wait(<Future<ArtworkResult?>>[first, active, ...history]);
    final terms = requests.map((r) => r.$2.queryParameters['term']).toList();
    expect(terms.first, 'Erster T');
    expect(terms.indexOf('Aktiv T'), lessThan(terms.indexOf('Verlauf1 T')));
  });

  test('Max. 2 parallele Anfragen', () async {
    var running = 0;
    var maxRunning = 0;
    final s = ItunesArtworkService(
      client: MockClient((r) async {
        running++;
        maxRunning = running > maxRunning ? running : maxRunning;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        running--;
        return http.Response(_hit, 200);
      }),
      clock: clock,
      sleep: (d) async => clock.advance(d),
    );
    await Future.wait(<Future<ArtworkResult?>>[
      for (var i = 0; i < 6; i++) s.lookup(_t('P$i', 'T')),
    ]);
    expect(maxRunning, 2);
  });

  test('429 -> 5 min Pause ohne Negativ-Cache', () async {
    var status = 429;
    final s = service((_) => http.Response('', status));
    expect(await s.lookup(_t('A', 'B')), isNull);
    expect(await s.lookup(_t('C', 'D')), isNull);
    expect(requests, hasLength(1));
    clock.advance(const Duration(minutes: 5, seconds: 1));
    status = 200;
    final s2 = await s.lookup(_t('A', 'B'));
    expect(s2, isNull); // leere Antwort, aber neue Anfrage
    expect(requests, hasLength(2));
  });

  test('Netzwerkfehler wird nicht gecacht', () async {
    var fail = true;
    final s = service((_) {
      if (fail) throw http.ClientException('offline');
      return http.Response(_hit, 200);
    });
    expect(await s.lookup(_missy), isNull);
    fail = false;
    expect(await s.lookup(_missy), isNotNull);
  });

  test('Persistenter Cache: schreiben, laden, abgelaufene verwerfen', () async {
    String? saved;
    final store = CoverCacheStore(
      read: () => saved,
      write: (json) async => saved = json,
    );
    final s = service((r) {
      final term = r.url.queryParameters['term']!;
      return http.Response(term.startsWith('Missy') ? _hit : _empty, 200);
    }, store: store);
    await s.lookup(_missy);
    await s.lookup(_t('Miss', 'Y'));
    await s.flush();
    expect(saved, contains('get ur freak on'));

    clock.advance(const Duration(days: 2));
    final reloaded = service((_) => http.Response(_empty, 200), store: store);
    final before = requests.length;
    expect((await reloaded.lookup(_missy))!.artworkUrl, isNotNull);
    expect(requests.length, before);
    // Negativtreffer (1 Tag) ist abgelaufen -> neue Anfrage.
    await reloaded.lookup(_t('Miss', 'Y'));
    expect(requests.length, before + 1);
  });

  test('LRU begrenzt auf maxEntries', () async {
    final s = ItunesArtworkService(
      client: MockClient((r) async {
        requests.add((clock.now(), r.url));
        return http.Response(_hit, 200);
      }),
      clock: clock,
      sleep: (d) async => clock.advance(d),
      maxEntries: 2,
    );
    await s.lookup(_t('A', '1'));
    await s.lookup(_t('B', '2'));
    await s.lookup(_t('A', '1')); // A wird juengster
    await s.lookup(_t('C', '3')); // verdraengt B
    expect(requests, hasLength(3));
    await s.lookup(_t('A', '1'));
    expect(requests, hasLength(3));
    await s.lookup(_t('B', '2'));
    expect(requests, hasLength(4));
  });

  group('Treffer-Pruefung (D8)', () {
    test(
      'fremder Treffer zaehlt nicht: Senderlogo statt falschem Cover',
      () async {
        final s = service((_) => http.Response(_hit, 200));
        expect(await s.lookup(_t('Wincent Weiss', 'Zusammen')), isNull);
      },
    );

    test('waehlt unter mehreren Ergebnissen das passende', () {
      const body =
          '{"results":['
          '{"artistName":"Karel Gott","trackName":"Biene Maja",'
          '"artworkUrl100":"https://x/a/100x100bb.jpg"},'
          '{"artistName":"Wincent Weiss","trackName":"Zusammen (Radio Edit)",'
          '"artworkUrl100":"https://x/b/100x100bb.jpg"}]}';
      final r = ItunesArtworkService.parseSearch(
        body,
        track: _t('Wincent Weiss', 'Zusammen'),
      );
      expect(r!.artworkUrl, 'https://x/b/600x600bb.jpg');
    });

    test('Kuenstler mit feat./& und Satzzeichen', () {
      bool m(String a, String t, String ia, String it) =>
          ItunesArtworkService.matchesTrack(_t(a, t), artist: ia, title: it);
      expect(
        m(
          'Missy Elliott feat. Ciara',
          'Lose Control',
          'Missy Elliott',
          'Lose Control (feat. Ciara & Fatman Scoop)',
        ),
        isTrue,
      );
      expect(
        m(
          'Simon & Garfunkel',
          'Mrs. Robinson',
          'Simon & Garfunkel',
          'Mrs Robinson',
        ),
        isTrue,
      );
      expect(m('Björk', 'Jóga', 'Björk', 'Jóga'), isTrue);
      expect(m('A', 'Song', 'B', 'Song'), isFalse);
      expect(
        m('Wincent Weiss', 'Zusammen', 'Karel Gott', 'Biene Maja'),
        isFalse,
      );
    });
  });

  test('parseSearch tolerant', () {
    expect(ItunesArtworkService.parseSearch('kein json'), isNull);
    expect(ItunesArtworkService.parseSearch('{"results":"x"}'), isNull);
    expect(ItunesArtworkService.parseSearch(_empty), isNull);
    expect(
      ItunesArtworkService.parseSearch(
        '{"results":[{"artworkUrl100":"http://unsicher/100x100bb.jpg"}]}',
      ),
      isNull,
    );
  });
}
