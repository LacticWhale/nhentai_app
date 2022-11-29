import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:nhentai/data_model.dart';

import 'api.dart';
import 'prefs.dart';
import 'screen/pages/book.dart';
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

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   static final String userAgent = 'nhentai_app/1.0.0+dev.3 ${Platform.operatingSystem}';

//   static Map<String, String> get headers => {
//       'set-cookies': (api.client as HttpClientWithCookies).cachedCookie.toString(),
//       'User-Agent': MyApp.userAgent,
//   };

//   @override
//   Widget build(BuildContext context) => MaterialApp(
//       title: 'Flutter Demo',
//       darkTheme: ThemeData(
//         colorScheme: const ColorScheme(
//           brightness: Brightness.dark,
//           primary: Colors.pink,
//           background: Color.fromARGB(0xff, 0x1f, 0x1f, 0x1f),
//           onPrimary: Colors.black,
//           secondary: Colors.white,
//           onSecondary: Colors.black,
//           error: Colors.red,
//           onError: Colors.black,
//           onBackground: Colors.black,
//           surface: Colors.pink,
//           surfaceVariant: Color.fromARGB(0xff, 0x1f, 0x1f, 0x1f),
//           onSurface: Colors.black,
//         ),
//       ),
//       home: HomePage(
//         includedTags: storage.selectedTagsBox.values
//           .where((tag) => tag.state == TagState.included),
//         excludedTags: storage.selectedTagsBox.values
//           .where((tag) => tag.state == TagState.excluded),
//       ),
//     );
// }
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final String userAgent = 'nhentai_app/1.0.0+dev.3 ${Platform.operatingSystem}';

  static Map<String, String> get headers => {
      'set-cookies': (api.client as HttpClientWithCookies).cachedCookie.toString(),
      'User-Agent': MyApp.userAgent,
  };

  @override
  State createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();

    initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();

    super.dispose();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    final appLink = await _appLinks.getInitialAppLink();
    if (appLink != null) {
      if (kDebugMode) {
        print('getInitialAppLink: $appLink');
      }
      openAppLink(appLink);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (kDebugMode) {
        print('onAppLink: $uri');
      }
      openAppLink(uri);
    });
  }

  Future<void> openAppLink(Uri uri) async {
    if(kDebugMode) {
      print(_navigatorKey.currentState);
      print(uri.path);
    }
    _navigatorKey.currentState?.pushNamed(uri.path);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
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
      navigatorKey: _navigatorKey,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final routeName = settings.name;
        if(kDebugMode)
          print('Route: $routeName $settings');
        if (routeName != null) {
          if (routeName.startsWith('/g/')) {
            if(kDebugMode)
              print('loading book');
            return MaterialPageRoute(
              builder: (context) => LoadBook(id: int.tryParse(routeName.substring(3)) ?? -1),
            );
        }

        return MaterialPageRoute(
          builder: (context) => const HomePage(),
          settings: settings,
        );
      }
    },
  );
}

class LoadBook extends StatelessWidget {
  const LoadBook({
    required this.id,
    super.key, 
  });

  final int id;

  @override
  Widget build(BuildContext context) => FutureBuilder<Book?>(
    future: getBook(id),
    builder: (context, snapshot) {
      if(kDebugMode)
        print(id);
      if(snapshot.connectionState != ConnectionState.done)
        return const Material(child: SafeArea(child: Center(child: CircularProgressIndicator(),)),);
      else if(snapshot.data == null) {
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
              body: Center(child: Text('Book $id not found.')),
              floatingActionButton: Card(
                child: TextButton(
                  child: const Text('Update cookies.'),
                  onPressed: () async {
                    (api.client as HttpClientWithCookies)
                      .cookieManager
                      .clearCookies()
                      .then((value) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => LoadBook(id: id,),
                          ),
                        );
                      });
                  },
                ),
              ),
            ),
          ),
        );
      }
      else 
        return BookPage(book: snapshot.data!);
    },
  );

  Future<Book?> getBook(int id) async => id == -1 ? null : api.getBook(id); 
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('id', id));
  }

}
