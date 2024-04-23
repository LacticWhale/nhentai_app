part of 'app.dart';

// GoRouter configuration
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/search',
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesPage(), 
    ),
    GoRoute(
      path: '/tags',
      builder: (context, state) => const TagSelectorPage(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final extra = state.extra;
        final drawer = state.uri.queryParameters['drawer'] == 'true' || state.uri.queryParameters['drawer'] == null; 
        final query = state.uri.queryParameters['query'] ?? '*';
        final page = int.parse(state.uri.queryParameters['page'] ?? '1');
        final pages = int.tryParse(state.uri.queryParameters['pages'] ?? '');

        if (extra is! Map)
          return HomePage(
            query: query,
            page: page,
            pages: pages,
            drawer: drawer,
          ); 

        final include = extra['include'] as List<Tag>? ?? [];
        final exclude = extra['exclude'] as List<Tag>? ?? [];

        return HomePage(
          includedTags: include,
          excludedTags: exclude,

          query: query,
          page: page,
          pages: pages,
          drawer: drawer,
        );
      },
    ),
    GoRoute(
      path: '/book/:id',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! Book) {
          final id = int.tryParse(state.pathParameters['id'] ?? 'invalid');
          if (id == null) 
            // TODO: create exception
            throw Exception('id is not provided number');

          return FutureBuilder(
            future: api.getBook(id), 
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // TODO: add logging
                print(snapshot.error);

                return ErrorWidget(snapshot.error!);
              }

              if (snapshot.hasData) {
                return BookPage(book: snapshot.data!);
              }

              return const Center(child: CircularProgressIndicator());
            },
          );
        }

        return BookPage(book: extra);
      },
    ),
  ],
);
