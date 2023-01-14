import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:nhentai/data_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uni_links/uni_links.dart';

import 'api.dart';
import 'prefs.dart';
import 'screen/pages/book.dart';
import 'screen/pages/home.dart';
import 'screen/webview/nhentai.net.dart';

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
    MaterialApp(
      title: 'NhentaiApp',
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
      home: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final String userAgent = '${packageInfo.packageName}/${packageInfo.version} ${Platform.operatingSystem}';

  static Map<String, String> get headers => {
      'set-cookies': (api.client as HttpClientWithCookies).cachedCookie.toString(),
      'User-Agent': MyApp.userAgent,
  };

  @override
  State createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _initialPath;

  @override
  void initState() {
    super.initState();

    // ignore: discarded_futures
    initUniLinks();
  }

  Future<void> initUniLinks() async {
    try {
      _initialPath = Uri.tryParse(await getInitialLink() ?? '/')?.path ?? '/';
    } catch (e) {
      _initialPath = '/';
    }

    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    if(_initialPath == null)
      return const Material(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    else if(_initialPath!.startsWith('/g/')) {
      final id = int.tryParse(_initialPath!.substring(_initialPath!.indexOf('/g/') + 3));
      if(id == null)
        return Material(
          child: Center(
            child: Text(_initialPath ?? ''),
          ),
        ); 
      return LoadBook(
        id: id,
      );
    } else if(_initialPath == '/') {
      return const HomePage();
    } else 
      return Material(
        child: Center(
          child: Text(_initialPath ?? ''),
        ),
      ); 
  }
}

class LoadBook extends StatefulWidget {
  const LoadBook({
    required this.id,
    super.key,
  });

  final int id;

  @override
  State<StatefulWidget> createState() => LoadBookState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('id', id));
  }

}

class LoadBookState extends State<LoadBook> {
  @override
  Widget build(BuildContext context) => FutureBuilder<Book?>(
    // ignore: discarded_futures
    future: getBook(widget.id),
    builder: (context, snapshot) {
      if(kDebugMode)
        print(widget.id);
      if(snapshot.connectionState != ConnectionState.done)
        return const Material(child: SafeArea(child: Center(child: CircularProgressIndicator(),)),);
      else if(snapshot.data != null) 
        return BookPage(book: snapshot.data!);
      else
        return Material(
          child: SafeArea(
            child: Scaffold(
              appBar: AppBar(
                actions: [
                  IconButton(
                    onPressed: () async => Navigator.pop(context), 
                    icon: const Icon(Icons.arrow_back),
                  ),
                ],
              ),
              body: Center(child: Text('Book ${widget.id} not found.')),
              floatingActionButton: Card(
                child: TextButton(
                  child: const Text('Update cookies.'),
                  onPressed: () async => (api.client as HttpClientWithCookies)
                    .clearCookies()
                    .then((value) => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const NHentaiWebView(),
                      ),
                    ),).then((value) async => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => LoadBook(id: widget.id),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    },
  );

  Future<Book?> getBook(int id) async => id == -1 ? null : api.getBook(id);

}
