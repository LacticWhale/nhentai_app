import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../api.dart';
import '../../main.dart';


class NHentaiWebView extends StatefulWidget {
  const NHentaiWebView({super.key});

  @override
  State<NHentaiWebView> createState() => _NHentaiWebViewState();
}

class _NHentaiWebViewState extends State<NHentaiWebView> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: WebView(
        initialUrl: 'https://nhentai.net/api/galleries/search?query=*',
        userAgent: MyApp.userAgent,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (webViewController) async {
          _controller.complete(webViewController);
        },
        onPageFinished: (url) async {
          if(await (api.client as HttpClientWithCookies).cfClearance != null) 
            Navigator.pop(context);
          if (kDebugMode) {
            print('Page finished loading: $url');
          }
        },
        gestureNavigationEnabled: true,
      ),
    );
}
