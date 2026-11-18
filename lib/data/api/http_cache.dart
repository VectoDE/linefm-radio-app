import 'package:http/http.dart' as http;

/// HTTP-Cache mit max-age und If-Modified-Since (Spec 3.3). Stub, P03.
class HttpCache {
  HttpCache({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<http.Response> get(Uri uri) => _client.get(uri);

  void close() => _client.close();
}
