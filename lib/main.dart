import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'prefs.dart';

Storage storage = Storage();
Preferences preferences = Preferences(storage: storage);

late PackageInfo packageInfo;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.init(cacheProvider: storage);

  packageInfo = await PackageInfo.fromPlatform();
  
  if(kDebugMode)
    print(MyApp.userAgent);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const MyApp(),
  );
}
