import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:nhentai/nhentai.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

import 'app.dart';
import 'main.dart';
import 'prefs.dart';

class CloudflareCookieManager {
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
}

final cfManager = CloudflareCookieManager();  

final api = API(
  userAgent: MyApp.userAgent,
  beforeRequest: beforeRequest,
);

FutureOr<void> beforeRequest(Request request) async {
  final req = Request('GET', Uri.parse('https://echo-http-requests.appspot.com/echo'));
  req.headers['Cookie'] = (await cfManager.cfClearance).toString();

  final response = await Response.fromStream(await api.client.send(req));
  throw ApiClientException('a', originalException: Exception());
  print(response.body);
}
