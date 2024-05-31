import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../api.dart';
import '../../app.dart';

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
              if (!context.mounted) 
                return;
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
        // ..loadRequest(Uri.parse('https://echo-http-requests.appspot.com/echo'))
        ..loadRequest(Uri.parse('https://nhentai.net/api/galleries/search?query=*'))
        ;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Flutter Simple Example')),
    body: Stack(
      children: [
        WebViewWidget(controller: _controller),
        // Positioned(
        //   bottom: 0,
        //   child: BlocBuilder<WebViewBloc, WebViewState>(builder: (context, state) => 
        //     Column(
        //       mainAxisSize: MainAxisSize.min,
        //       children: [
        //         Text('Cookie: ${state.cookie}', maxLines: 1, overflow: TextOverflow.clip),
        //         Text('Path: ${state.path}', maxLines: 1, overflow: TextOverflow.clip),
        //       ],
        //     ),
        //   ), 
        // ),
      ],
    ),
  );
}
