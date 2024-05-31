import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'bloc/app_state_bloc.dart';
import 'prefs.dart';

Storage storage = Storage();
Preferences preferences = Preferences(storage: storage);

late PackageInfo packageInfo;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.init(cacheProvider: storage);

  packageInfo = await PackageInfo.fromPlatform();
  
  if(kDebugMode) {
    // final body = await (api as dynamic)._getJson(Uri.parse('https://echo-http-requests.appspot.com/echo'));
    // print(body);
    print(MyApp.userAgent);
  }

  final state = AppState();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MyApp(initialState: state),
  );
}
