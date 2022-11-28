import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'api.dart';
import 'prefs.dart';
import 'screen/pages/home.dart';
import 'widgets/tag_block.dart';

Storage storage = Storage();
Preferences preferences = Preferences(storage: storage);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.init(cacheProvider: storage);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final String userAgent = 'nhentai_app/1.0.0+dev.3 ${Platform.operatingSystem}';

  static Map<String, String> get headers => {
      'set-cookies': (api.client as HttpClientWithCookies).cachedCookie.toString(),
      'User-Agent': MyApp.userAgent,
  };

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Flutter Demo',
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
      home: HomePage(
        includedTags: storage.selectedTagsBox.values
          .where((tag) => tag.state == TagState.included),
        excludedTags: storage.selectedTagsBox.values
          .where((tag) => tag.state == TagState.excluded),
      ),
    );
}
