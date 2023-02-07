// ignore_for_file: avoid_setters_without_getters

import 'dart:async';
import 'dart:io';

/// [HttpClient] implementation which can resolve proxy server asynchronously.
class DelayedProxyHttpClient implements HttpClient {
  /// System [HttpClient] will be used internally. [HttpOverrides] is ignored.
  DelayedProxyHttpClient({SecurityContext? context}) : _inner = _DummyHttpOverrides().createHttpClient(context);

  DelayedProxyHttpClient.withInner(this._inner);

  final HttpClient _inner;
  FutureOr<String> Function(Uri url)? _findProxy = HttpClient.findProxyFromEnvironment;

  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set autoUncompress(bool autoUncompress) => _inner.autoUncompress = autoUncompress;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set connectionTimeout(Duration? connectionTimeout) => _inner.connectionTimeout = connectionTimeout;

  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set idleTimeout(Duration idleTimeout) => _inner.idleTimeout = idleTimeout;

  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set maxConnectionsPerHost(int? maxConnectionsPerHost) => _inner.maxConnectionsPerHost = maxConnectionsPerHost;

  @override
  String? get userAgent => _inner.userAgent;
  @override
  set userAgent(String? userAgent) => _inner.userAgent = userAgent;

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) => _inner.authenticate = f;

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) =>
      _inner.authenticateProxy = f;

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) =>
      _inner.badCertificateCallback = callback;

  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) =>
      _inner.connectionFactory = f;

  /// Sets the function used to resolve the proxy server to be used for
  /// opening a HTTP connection to the specified [url]. If this
  /// function is not set, direct connections will always be used.
  ///
  /// The string returned by [f] must be in the format used by browser
  /// PAC (proxy auto-config) scripts. That is either
  ///
  ///     "DIRECT"
  ///
  /// for using a direct connection or
  ///
  ///     "PROXY host:port"
  ///
  /// for using the proxy server `host` on port `port`.
  ///
  /// A configuration can contain several configuration elements
  /// separated by semicolons, e.g.
  ///
  ///     "PROXY host:port; PROXY host2:port2; DIRECT"
  ///
  /// The static function [findProxyFromEnvironment] on [HttpClient] class can
  /// be used to implement proxy server resolving based on environment
  /// variables.
  ///
  /// This will override the value set for [findProxyAsync].
  @override
  set findProxy(String Function(Uri url)? f) => _findProxy = f;

  /// Sets the function used to asynchronously resolve the proxy server to be used for
  /// opening a HTTP connection to the specified [url]. If this
  /// function is not set, direct connections will always be used.
  ///
  /// The string returned by [f] must be in the format used by browser
  /// PAC (proxy auto-config) scripts. That is either
  ///
  ///     "DIRECT"
  ///
  /// for using a direct connection or
  ///
  ///     "PROXY host:port"
  ///
  /// for using the proxy server `host` on port `port`.
  ///
  /// A configuration can contain several configuration elements
  /// separated by semicolons, e.g.
  ///
  ///     "PROXY host:port; PROXY host2:port2; DIRECT"
  ///
  /// The static function [findProxyFromEnvironment] on [HttpClient] class can
  /// be used to implement proxy server resolving based on environment
  /// variables.
  ///
  /// This will override the value set for [findProxy].
  set findProxyAsync(FutureOr<String> Function(Uri url)? f) => _findProxy = f;

  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {
    _inner.addCredentials(url, realm, credentials);
  }

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {
    _inner.addProxyCredentials(host, port, realm, credentials);
  }

  @override
  void close({bool force = false}) {
    _inner.close(force: force);
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) => open("delete", host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl("delete", url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) => open("get", host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl("get", url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) => open("head", host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl("head", url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) => open("patch", host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl("patch", url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) => open("post", host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl("post", url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) => open("put", host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl("put", url);

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) {
    const int hashMark = 0x23;
    const int questionMark = 0x3f;
    int fragmentStart = path.length;
    int queryStart = path.length;
    for (int i = path.length - 1; i >= 0; i--) {
      final char = path.codeUnitAt(i);
      if (char == hashMark) {
        fragmentStart = i;
        queryStart = i;
      } else if (char == questionMark) {
        queryStart = i;
      }
    }
    String? query;
    if (queryStart < fragmentStart) {
      query = path.substring(queryStart + 1, fragmentStart);
      // ignore: parameter_assignments
      path = path.substring(0, queryStart);
    }
    final uri = Uri(scheme: "http", host: host, port: port, path: path, query: query);
    return _openUrl(method, uri);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => _openUrl(method, url);

  Future<HttpClientRequest> _openUrl(String method, Uri url) async {
    _inner.findProxy = (_) => (Zone.current[_kFindProxyToken] as String?) ?? "DIRECT";

    final findProxy = _findProxy;
    String proxy = "DIRECT";
    if (findProxy != null) {
      final proxyFuture = findProxy(url);
      proxy = proxyFuture is String ? proxyFuture : await proxyFuture;
    }

    return runZoned(
      () => _inner.openUrl(method, url),
      zoneValues: {_kFindProxyToken: proxy},
    );
  }
}

const _kFindProxyToken = "proxy_for_url";

class _DummyHttpOverrides extends HttpOverrides {}
