import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/data/api/http_cache.dart';
import 'package:linefm_radio/data/api/laut_api.dart';

final _uri = Uri.parse('https://api.laut.fm/station/linefm/listeners');

void main() {
  late FakeClock clock;
  late List<http.Request> requests;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 11, 18, 20));
    requests = <http.Request>[];
  });

  HttpCache cacheWith(
    FutureOr<http.Response> Function(http.Request) handler, {
    bool conditional = true,
  }) => HttpCache(
    client: MockClient((r) async {
      requests.add(r);
      return handler(r);
    }),
    clock: clock,
    conditionalHeaders: conditional,
  );

  test('max-age minus Age wird respektiert', () async {
    final cache = cacheWith(
      (_) => http.Response(
        '1',
        200,
        headers: <String, String>{
          'cache-control': 'public, must-revalidate, max-age=60',
          'age': '20',
          'etag': 'W/"a"',
        },
      ),
    );
    await cache.get(_uri);
    clock.advance(const Duration(seconds: 39));
    final hit = await cache.get(_uri);
    expect(hit.headers[HttpCache.cacheHeader], 'hit');
    expect(requests, hasLength(1));
    clock.advance(const Duration(seconds: 2));
    await cache.get(_uri);
    expect(requests, hasLength(2));
  });

  test('ohne max-age gilt Expires minus Date (laut.fm current_song)', () {
    final received = DateTime.utc(2026, 11, 18, 20, 0, 5);
    final until = HttpCache.freshUntil(<String, String>{
      'cache-control': 'public, must-revalidate',
      'date': 'Wed, 18 Nov 2026 20:13:00 GMT',
      'expires': 'Wed, 18 Nov 2026 20:13:57 GMT',
      'age': '97',
    }, received);
    expect(until, received.add(const Duration(seconds: 57)));
  });

  test('abgelaufenes Expires und no-cache sind sofort veraltet', () {
    final received = DateTime.utc(2026);
    expect(
      HttpCache.freshUntil(<String, String>{
        'date': 'Wed, 18 Nov 2026 20:10:58 GMT',
        'expires': 'Wed, 18 Nov 2026 20:01:55 GMT',
      }, received),
      received,
    );
    expect(
      HttpCache.freshUntil(<String, String>{
        'cache-control': 'no-cache, max-age=600',
      }, received),
      received,
    );
    expect(HttpCache.freshUntil(const <String, String>{}, received), received);
  });

  test('HTTP-Datum ohne dart:io', () {
    expect(
      HttpCache.parseHttpDate('Wed, 18 Nov 2026 20:11:28 GMT'),
      DateTime.utc(2026, 11, 18, 20, 11, 28),
    );
    expect(
      HttpCache.parseHttpDate('Wednesday, 18-Nov-26 20:11:28 GMT'),
      DateTime.utc(2026, 11, 18, 20, 11, 28),
    );
    expect(HttpCache.parseHttpDate('kaputt'), isNull);
  });

  test('304 nutzt den Cache und sendet Bedingungs-Header', () async {
    var calls = 0;
    final cache = cacheWith((r) {
      calls++;
      if (calls == 1) {
        return http.Response(
          '7',
          200,
          headers: <String, String>{
            'cache-control': 'max-age=60',
            'etag': 'W/"x"',
            'date': 'Wed, 18 Nov 2026 20:00:00 GMT',
          },
        );
      }
      return http.Response(
        '',
        304,
        headers: <String, String>{'cache-control': 'max-age=60'},
      );
    });
    expect((await cache.get(_uri)).body, '7');
    clock.advance(const Duration(seconds: 61));
    final again = await cache.get(_uri);
    expect(again.statusCode, 200);
    expect(again.body, '7');
    expect(requests.last.headers['If-None-Match'], 'W/"x"');
    expect(
      requests.last.headers['If-Modified-Since'],
      'Wed, 18 Nov 2026 20:00:00 GMT',
    );
    // 304 hat die Frische erneuert.
    clock.advance(const Duration(seconds: 30));
    await cache.get(_uri);
    expect(requests, hasLength(2));
  });

  test(
    'Web-Modus: keine Bedingungs-Header (CORS-Preflight vermeiden)',
    () async {
      final cache = cacheWith(
        (_) => http.Response(
          '1',
          200,
          headers: <String, String>{'etag': 'W/"x"', 'date': 'x'},
        ),
        conditional: false,
      );
      await cache.get(_uri);
      await cache.get(_uri);
      expect(requests, hasLength(2));
      expect(requests.last.headers.containsKey('If-None-Match'), isFalse);
      expect(requests.last.headers.containsKey('If-Modified-Since'), isFalse);
    },
  );

  test('Deduplizierung: gleiche URL in Arbeit -> eine Anfrage', () async {
    final gate = Completer<void>();
    final cache = cacheWith((_) async {
      await gate.future;
      return http.Response('1', 200);
    });
    final a = cache.get(_uri);
    final b = cache.get(_uri);
    gate.complete();
    final results = await Future.wait(<Future<http.Response>>[a, b]);
    expect(results.map((r) => r.body), <String>['1', '1']);
    expect(requests, hasLength(1));
  });

  test('Netzwerkfehler liefert veralteten Eintrag, sonst Exception', () async {
    var fail = false;
    final cache = cacheWith((_) {
      if (fail) throw http.ClientException('offline');
      return http.Response('9', 200);
    });
    await expectLater(cache.get(Uri.parse('https://x/neu')), completes);
    fail = true;
    final stale = await cache.get(Uri.parse('https://x/neu'));
    expect(stale.body, '9');
    expect(stale.headers[HttpCache.staleHeader], '1');
    await expectLater(
      cache.get(Uri.parse('https://x/anders')),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('Fehlerstatus wird nicht gecacht', () async {
    final cache = cacheWith((_) => http.Response('nope', 503));
    await cache.get(_uri);
    await cache.get(_uri);
    expect(requests, hasLength(2));
  });

  test('HttpLautApi baut URLs und wirft bei HTTP-Fehlern', () async {
    final api = HttpLautApi(
      cache: cacheWith((r) {
        if (r.url.path.endsWith('/listeners')) return http.Response('5', 200);
        return http.Response('{}', 404);
      }),
    );
    expect(await api.listeners('linefm'), 5);
    expect(requests.single.url.toString(), _uri.toString());
    await expectLater(
      api.currentSong('linefm'),
      throwsA(
        isA<LautApiException>().having((e) => e.statusCode, 'status', 404),
      ),
    );
  });
}
