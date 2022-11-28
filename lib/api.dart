import 'dart:io';

import 'package:core_mixins/http/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:nhentai/nhentai.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

import 'main.dart';

class ApiWithCache extends API {
  ApiWithCache({
    super.client,
    super.hosts,
    super.maxRetries,
  });

  final _cache = <Uri, dynamic>{};

  @override
  Future<dynamic> getJson(Uri url) {
    if(_cache.containsKey(url))
      return Future.value(_cache[url]!);
    return super.getJson(url);
  }
}

class HttpClientWithCookies with HttpClientMixin implements HttpClient {
  HttpClientWithCookies(this.httpClient);

  @override
  final HttpClient httpClient;

  final cookieManager = WebviewCookieManager();

  Cookie? cachedCookie;

  Future<Cookie?> get cfClearance async {
    final cookies = await cookieManager.getCookies('https://nhentai.net/');
    if(cookies.isEmpty) 
      return null;

    final cfClearance = cookies.where((element) => element.name == 'cf_clearance');
    if(cfClearance.isEmpty) 
      return null;

    return cachedCookie = cfClearance.first;
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

final api = ApiWithCache(
  client: httpClient,
);
