import 'dart:io';

import 'package:collection/collection.dart';
import 'package:core_mixins/http/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:nhentai/nhentai.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

import 'main.dart';
import 'prefs.dart';

class HttpClientWithCookies with HttpClientMixin implements HttpClient {
  HttpClientWithCookies(this.httpClient);

  @override
  final HttpClient httpClient;

  final cookieManager = WebviewCookieManager();

  Future<Cookie?> get _platformSpecificCookie async {
    if(Platform.isAndroid || Platform.isIOS) {
      final cookies = await cookieManager.getCookies('https://nhentai.net/');
      if(cookies.isEmpty) 
        return null;
      
      return cookies.firstWhereOrNull((element) => element.name == 'cf_clearance');
    } else {
      throw UnimplementedError();
    }
  }

  Future<Cookie?> get cfClearance async {
    final cookieValue = storage.getString(Preferences.kCfClearanceValue);
    if (cookieValue != null)
      return Cookie('cf_clearance', cookieValue);

    final cookie = await _platformSpecificCookie;
    await storage.setString(Preferences.kCfClearanceValue, cookie?.value);
    return cookie;
  }

  Future<void> clearCookies() => Future.wait([
    storage.remove(Preferences.kCfClearanceValue),
    if(Platform.isAndroid || Platform.isIOS)
      cookieManager.clearCookies(),
  ]); 
  // async {
  //   await storage.remove(Preferences.kCfClearanceValue);
  //   return cookieManager.clearCookies();
  // }

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
