import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../api.dart';
import '../../app.dart';
import '../../main.dart';

class NHentaiWebView extends StatefulWidget {
  const NHentaiWebView({super.key});

  @override
  State<NHentaiWebView> createState() => _NHentaiWebViewState();
}

class _NHentaiWebViewState extends State<NHentaiWebView> {
  final WebViewController _controller = WebViewController();

  @override
  void initState() {
    super.initState();

    scheduleMicrotask(() async {
      _controller
        ..setUserAgent(MyApp.userAgent)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              // Update loading bar.
            },
            onPageFinished: (url) async {
              final cookie = await cfManager.cfClearance;
              if (cookie != null) {
                if (mounted)
                  Navigator.of(context).pop(cookie);
              }

              if (kDebugMode) {
                print('Page finished loading: $url');
              }
            },
          ),
        )
        ..loadRequest(Uri.parse('https://echo-http-requests.appspot.com/echo'))
        // ..loadRequest(
        //     Uri.parse('https://nhentai.net/api/galleries/search?query=*'))
        ;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Flutter Simple Example')),
    body: WebViewWidget(controller: _controller),
  );
}
