import 'dart:io';

import 'package:core_mixins/http/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:nhentai/nhentai.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

import 'main.dart';

class HttpClientWithCookies with HttpClientMixin implements HttpClient {
  HttpClientWithCookies(this.httpClient);

  @override
  final HttpClient httpClient;

  final cookieManager = WebviewCookieManager();

  Cookie? cachedCookie = Cookie('cf_clearance', 'fZZImzUICLbohYRO2MXwNIwC5EqUeAVnK98HHCIlV4A-1672398359-0-150');

  Future<Cookie?> get cfClearance async {
    if(cachedCookie != null)
      return cachedCookie;
    final cookies = await cookieManager.getCookies('https://nhentai.net/');
    if(cookies.isEmpty) 
      return null;

    final cfClearance = cookies.where((element) => element.name == 'cf_clearance');
    if(cfClearance.isEmpty) 
      return null;

    return cachedCookie = cfClearance.first;
  }

  Future<void> clearCookies() async {
    cachedCookie = null;
    return cookieManager.clearCookies();
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final request = await super.openUrl('GET', url);
    if(url.host.contains('nhentai.net')) {
      final cf = await cfClearance; 
      if (kDebugMode) 
        print('Request with cookies: $url');
      if (cf != null)
        request.cookies.add(cf);
    }

    return request;
  }
}

final httpClient = HttpClientWithCookies(HttpClient()
  ..userAgent = MyApp.userAgent
  ..connectionTimeout = const Duration(seconds: 15)
  ..idleTimeout = const Duration(seconds: 15)
,
);

final api = API(client: httpClient);
