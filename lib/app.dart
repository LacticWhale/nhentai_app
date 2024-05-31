import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nhentai/data_model.dart';

import 'api.dart';
import 'bloc/app_state_bloc.dart';
import 'main.dart';
import 'prefs.dart';
import 'screen/pages/book.dart';
import 'screen/pages/favorites.dart';
import 'screen/pages/history.dart';
import 'screen/pages/home.dart';
import 'screen/pages/settings.dart';
import 'screen/pages/tags.dart';

part 'router.dart';


class MyApp extends StatelessWidget {
  const MyApp({
    required this.initialState, 
    super.key,
  });

  final AppState initialState;

  // static final String userAgent =
  //   '${packageInfo.packageName}/${packageInfo.version} ${Platform.operatingSystem}';
  static const String userAgent =
    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.6422.147 Mobile Safari/537.36';

  static Map<String, String> get headers => {
    'set-cookies': storage.getString(Preferences.kCfClearanceValue) ?? '',
    'User-Agent': MyApp.userAgent,
  };

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AppBloc(initialState),
    child: MaterialApp.router(
      title: 'NhentaiApp',
      routerConfig: _router,
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.pink, 
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
    ),
  );
  
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppState>('initialState', initialState));
  }
}
