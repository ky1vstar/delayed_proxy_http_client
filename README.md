[![Dart CI](https://github.com/ky1vstar/delayed_proxy_http_client/actions/workflows/ci.yml/badge.svg)](https://github.com/ky1vstar/delayed_proxy_http_client/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/delayed_proxy_http_client.svg)](https://pub.dev/packages/delayed_proxy_http_client)

This lightweight package provides implementation of [HttpClient](https://api.flutter.dev/flutter/dart-io/HttpClient-class.html) extended with one property named [findProxyAsync](https://pub.dev/documentation/delayed_proxy_http_client/latest/delayed_proxy_http_client/DelayedProxyHttpClient/findProxyAsync.html).
It is designed to be used with packages like [system_proxy_resolver](https://pub.dev/packages/system_proxy_resolver) which can resolve proxy server dynamically based on PAC script configured in OS settings.

## Usage

To use this plugin, add `delayed_proxy_http_client` as a [dependency in your pubspec.yaml file](https://dart.dev/tools/pub/dependencies).

### Example

Here is small example that show you how to use the API.

```dart
final client = DelayedProxyHttpClient();
client.findProxyAsync = (url) async {
  await Future.delayed(const Duration(seconds: 3));
  return url.host == "pub.dev" ? "PROXY localhost:3128" : "DIRECT";
};

final request = await client.getUrl(Uri.parse("https://pub.dev"));
final response = await request.close();
await stdout.addStream(response);
```
