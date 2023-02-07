import 'dart:io';

import 'package:delayed_proxy_http_client/delayed_proxy_http_client.dart';

void main() async {
  final client = DelayedProxyHttpClient();
  client.findProxyAsync = (url) async {
    await Future.delayed(const Duration(seconds: 3));
    return url.host == "pub.dev" ? "PROXY localhost:3128" : "DIRECT";
  };

  final request = await client.getUrl(Uri.parse("https://pub.dev"));
  final response = await request.close();
  await stdout.addStream(response);
}
