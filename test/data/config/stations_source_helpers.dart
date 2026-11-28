import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
