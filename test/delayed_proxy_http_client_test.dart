import 'package:delayed_proxy_http_client/delayed_proxy_http_client.dart';
import 'package:test/test.dart';

void main() {
  test("delayed proxy is resolved", () async {
    const proxyHost = "someproxy";
    const proxyPort = 8080;

    String? resolvedProxyHost;
    int? resolvedProxyPort;

    final client = DelayedProxyHttpClient()
      ..findProxyAsync = (_) async {
        await Future.delayed(const Duration(seconds: 2));
        return "PROXY $proxyHost:$proxyPort";
      }
      ..connectionFactory = (url, proxyHost, proxyPort) {
        resolvedProxyHost = proxyHost;
        resolvedProxyPort = proxyPort;
        throw UnimplementedError();
      };

    await client.openUrl("GET", Uri.parse("https://example.com")).then<void>((_) => null, onError: (_) => null);

    expect(resolvedProxyHost, proxyHost);
    expect(resolvedProxyPort, proxyPort);
  });
}
