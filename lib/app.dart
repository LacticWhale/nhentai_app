import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhentai/data_model.dart';
import 'package:path/path.dart';

import 'api.dart';
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
  const MyApp({super.key});

  static final String userAgent =
    '${packageInfo.packageName}/${packageInfo.version} ${Platform.operatingSystem}';

  static Map<String, String> get headers => {
    'set-cookies': storage.getString(Preferences.kCfClearanceValue) ?? '',
    'User-Agent': SettingsPage.cachedAgent ?? MyApp.userAgent,
  };

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'NhentaiApp',
    routerConfig: _router,
    darkTheme: ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Colors.pink,
        background: Color.fromARGB(0xff, 0x1f, 0x1f, 0x1f),
        onPrimary: Colors.black,
        secondary: Colors.white,
        onSecondary: Colors.black,
        error: Colors.red,
        onError: Colors.black,
        onBackground: Colors.black,
        surface: Colors.pink,
        surfaceVariant: Color.fromARGB(0xff, 0x1f, 0x1f, 0x1f),
        onSurface: Colors.black,
      ),
    ),
    themeMode: ThemeMode.dark,
  );
}
