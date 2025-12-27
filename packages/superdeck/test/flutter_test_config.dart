import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global test configuration that runs before all tests.
///
/// This mocks HTTP and path_provider to prevent Google Fonts network/storage issues.
/// See: https://pub.dev/packages/google_fonts#testing
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Disable Google Fonts runtime fetching in tests.
  // The default_style.dart checks this flag and uses fallback fonts when disabled.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Mock path_provider to return a temp directory
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    },
  );

  // Override HTTP to return 200 with minimal data for font requests
  HttpOverrides.global = _MockHttpOverrides();

  await testMain();
}

/// HTTP overrides that return 404 responses for all requests.
class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

/// Mock HTTP client that returns 404 for all requests.
class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String? realm)? f) {}

  @override
  set authenticateProxy(
      Future<bool> Function(String host, int port, String scheme, String? realm)?
          f) {}

  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port)? callback) {}

  @override
  set connectionFactory(
      Future<ConnectionTask<Socket>> Function(
              Uri url, String? proxyHost, int? proxyPort)?
          f) {}

  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  set keyLog(Function(String line)? callback) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> headUrl(Uri url) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> patchUrl(Uri url) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> postUrl(Uri url) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> putUrl(Uri url) =>
      Future.value(_MockHttpClientRequest());
}

/// Mock request that returns a 404 response.
class _MockHttpClientRequest implements HttpClientRequest {
  @override
  bool bufferOutput = true;

  @override
  int contentLength = -1;

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) {}

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  String get method => 'GET';

  @override
  Uri get uri => Uri.parse('http://mock');

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => [];

  @override
  Future<HttpClientResponse> get done => Future.value(_MockHttpClientResponse());

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) => Future.value();

  @override
  Future<HttpClientResponse> close() => Future.value(_MockHttpClientResponse());

  @override
  Future flush() => Future.value();

  @override
  void write(Object? object) {}

  @override
  void writeAll(Iterable objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = '']) {}
}

/// Mock response that returns 404 to prevent Google Fonts from trying to parse invalid data.
/// When Google Fonts gets a 404, it gracefully falls back to platform fonts.
class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => 404;

  @override
  String get reasonPhrase => 'Not Found';

  @override
  int get contentLength => 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get persistentConnection => true;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => [];

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  X509Certificate? get certificate => null;

  @override
  List<Cookie> get cookies => [];

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  Future<Socket> detachSocket() => throw UnsupportedError('detachSocket');

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) =>
      Future.value(_MockHttpClientResponse());

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    // Return empty data for 404 response
    Timer.run(() {
      onDone?.call();
    });
    return _MockStreamSubscription();
  }
}

class _MockStreamSubscription implements StreamSubscription<List<int>> {
  @override
  Future<E> asFuture<E>([E? futureValue]) => Future.value(futureValue as E);

  @override
  Future cancel() => Future.value();

  @override
  bool get isPaused => false;

  @override
  void onData(void Function(List<int> data)? handleData) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void onError(Function? handleError) {}

  @override
  void pause([Future<void>? resumeSignal]) {}

  @override
  void resume() {}
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  bool chunkedTransferEncoding = false;

  @override
  int contentLength = -1;

  @override
  ContentType? contentType;

  @override
  DateTime? date;

  @override
  DateTime? expires;

  @override
  String? host;

  @override
  DateTime? ifModifiedSince;

  @override
  bool persistentConnection = true;

  @override
  int? port;

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void clear() {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {}

  @override
  void removeAll(String name) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  String? value(String name) => null;

  @override
  List<String>? operator [](String name) => null;
}
