import 'package:http/http.dart' as http;

import 'disposable.dart';

/// HTTP client service for downloading assets
class HttpClientService implements Disposable {
  final http.Client _client = http.Client();

  Future<http.Response> get(Uri url) => _client.get(url);

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
