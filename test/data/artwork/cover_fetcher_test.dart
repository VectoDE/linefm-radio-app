import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linefm_radio/data/artwork/cached_cover_image.dart';

void main() {
  final uri = Uri.parse('https://cdn.linefm.de/cover.jpg');

  test('returns the body of a normal response', () async {
    final client = MockClient((_) async => http.Response.bytes([1, 2, 3], 200));
    expect(await defaultCoverFetcher(uri, client: client), [1, 2, 3]);
  });

  test('rejects a declared Content-Length above the cap', () async {
    final client = MockClient(
      (_) async => http.Response.bytes(List<int>.filled(11, 0), 200),
    );
    await expectLater(
      defaultCoverFetcher(uri, client: client, maxBytes: 10),
      throwsA(isA<http.ClientException>()),
    );
  });

  test(
    'aborts a streamed body without length once it exceeds the cap',
    () async {
      var sent = 0;
      var cancelled = false;
      final controller = StreamController<List<int>>(
        onCancel: () => cancelled = true,
      );
      final client = MockClient.streaming((_, _) async {
        scheduleMicrotask(() async {
          for (var i = 0; i < 100 && !cancelled; i++) {
            sent++;
            controller.add(List<int>.filled(4, 0));
            await Future<void>.delayed(Duration.zero);
          }
          await controller.close();
        });
        return http.StreamedResponse(controller.stream, 200);
      });
      await expectLater(
        defaultCoverFetcher(uri, client: client, maxBytes: 10),
        throwsA(isA<http.ClientException>()),
      );
      expect(cancelled, isTrue);
      expect(sent, lessThan(100));
    },
  );

  test('rejects non-200 and empty bodies', () async {
    final notFound = MockClient((_) async => http.Response('', 404));
    final empty = MockClient((_) async => http.Response.bytes(<int>[], 200));
    await expectLater(
      defaultCoverFetcher(uri, client: notFound),
      throwsA(isA<http.ClientException>()),
    );
    await expectLater(
      defaultCoverFetcher(uri, client: empty),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('gives up when the server does not answer in time', () async {
    final never = Completer<http.StreamedResponse>();
    final client = MockClient.streaming((_, _) => never.future);
    await expectLater(
      defaultCoverFetcher(
        uri,
        client: client,
        timeout: const Duration(milliseconds: 50),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });
}
