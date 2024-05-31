import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../screen/webview/nhentai.net.dart';

class UpdateCookies extends StatelessWidget {
  const UpdateCookies({
    required this.error, 
    this.cb,
    super.key,
  });

  final Object error;
  final Function? cb;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          child: TextButton(
            child: const Text('Update cookies.'),
            onPressed: () async {
              cfManager
                .clearCookies().then((value) {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const NHentaiWebView(),
                    ),
                  ).then((value) async => await cb!.call());
                });
            },
          ),
        ),
        FilledButton(
          onPressed: () {
            // GoRouter.of(context).replace('?next');
            GoRouter.of(context).go(GoRouterState.of(context).uri.replace(queryParameters: Map.of(GoRouterState.of(context).uri.queryParameters)..addAll({'next': null})).toString());
          },
          child: const Text('Try loading next page.'),
        ),
        Text(error.toString()),
      ],
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Object>('error', error))
      ..add(DiagnosticsProperty<Function?>('cb2', cb));
  }
}
