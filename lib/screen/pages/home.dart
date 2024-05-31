import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhentai/nhentai.dart';
import 'package:preload_page_view/preload_page_view.dart';

import '/api.dart';
import '/extensions/string_add_query.dart';
import '/functions/create_gallery_card.dart';
import '/main.dart';
import '/widgets/exception_page.dart';
import '/widgets/my_navigation_bar.dart';
import '/widgets/selector.dart';
import '/widgets/tag_block.dart';
import '/widgets/update_cookies.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    this.query = '',
    this.page = 1,
    this.pages,
    this.includedTags,
    this.excludedTags,
    this.drawer = true,
    super.key,
  });

  final Iterable<Tag>? includedTags;
  final Iterable<Tag>? excludedTags;
  final String query;
  final int page;
  final int? pages;
  final bool drawer;

  @override
  State<StatefulWidget> createState() => _NewHomePageState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('pages', pages))
      ..add(IntProperty('page', page))
      ..add(StringProperty('query', query))
      ..add(IterableProperty<Tag>('tagsList', includedTags))
      ..add(IterableProperty<Tag>('excludedTags', excludedTags))
      ..add(DiagnosticsProperty<bool>('drawer', drawer));
  }
}

class SearchParameter {
  SearchParameter({
    this.query = '*',
    this.includedTags = const [],
    this.excludedTags = const [],
    this.minPages = 1,
    this.maxPages = -1,
  });
  
  String query;

  List<Tag> includedTags;
  List<Tag> excludedTags;

  // Minimum number of pages (inclusive) book can have.
  int minPages;
  // Maximum number of pages (inclusive) book can have. 
  int maxPages;

  // Combines all parameters into search string.
  String build() {
    final list = [
      if (query.isNotEmpty && query != '*')
        query,
      ...includedTags.map(SearchQueryTag.new),
      ...excludedTags.map(SearchQueryTag.new).map((e) => '-$e'),
      if (minPages > 0)
        'pages:>=$minPages',
      if (maxPages > 0)
        'pages:<=$maxPages',
    ];

    return list.isEmpty ? '*' : list.join(' ');
  }
}

class _NewHomePageState extends State<HomePage> {
  late SearchParameter _searchParameter;
  
  late int _page;
  int? _pages;

  late SearchSort _searchSort;

  late TextEditingController _searchBarController;
  late PreloadPageController _pageController;
  late MyNavigationBarController _appNavBarController;

  @override
  void initState() {
    _page = widget.page;

    final selectedTags = storage.selectedTagsBox.values;
    _searchSort = preferences.searchSort;

    _searchParameter = SearchParameter(
      query: widget.query,
      includedTags: List.from(widget.includedTags ?? 
        selectedTags.where((tag) => tag.state == TagState.included),
      ),
      excludedTags: List.from(widget.excludedTags ?? 
        selectedTags.where((tag) => tag.state == TagState.excluded),
      ),
    );   

    _searchBarController = TextEditingController(
      text: widget.query,
    );
    _pageController = PreloadPageController(
      initialPage: _page - 1,
    );
    _appNavBarController = MyNavigationBarController(
      initialPage: _page,
    );

    super.initState();
  }

  @override
  void dispose() {
    _searchBarController.dispose();
    _pageController.dispose();
    _appNavBarController.dispose();

    super.dispose();
  }

  Widget buildInitial(BuildContext context) => FutureBuilder<Search>(
    // ignore: discarded_futures
    future: api.searchSinglePage(_searchParameter.build(),
      sort: _searchSort,
      page: widget.page,
    ),
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return Scaffold(
          appBar: appBar,
          drawer: widget.drawer ? drawer : null,
          body: ExceptionPage(
            onRefresh: () async => setState(() {}),
            child: UpdateCookies(
              error: snapshot.error!, 
              cb: () => setState(() {}),
            ),
          ),
        );

      if (!snapshot.hasData)
        return Scaffold(
          appBar: appBar,
          drawer: drawer,
          body: loadingBody,
        );

      final search = snapshot.data!;
      _pages = search.pages;
      _appNavBarController.changePages(_pages!);

      return buildView(context);
    },
  );

  Widget buildView(BuildContext context) => Scaffold(
    appBar: appBar,
    drawer: widget.drawer ? drawer : null,
    bottomNavigationBar: MyNavigationBar(
      controller: _appNavBarController, 
      onLeft: () async {
        if(_page > 1)
          _pageController.previousPage(
            duration: const Duration(milliseconds: 200), 
            curve: Curves.decelerate,
          );
      },
      onText: () => unawaited(
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setInnerState) => Selector(
              pages: _pages!,
              page: _page,
              onJump: (page) => _pageController.jumpToPage(page),
            ),
          ),
        ),
      ),
      onRight: () async {
        if(_page < _pages!) 
          _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.decelerate);
      },
    ),
    body: PreloadPageView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      onPageChanged: (value) => _appNavBarController.changeCurrentPage(_page = value + 1),
      controller: _pageController,
      preloadPagesCount: 3,
      itemCount: _pages! - 1,
      itemBuilder: (context, index) => FutureBuilder<Search?>(
        // ignore: discarded_futures
        future: api.searchSinglePage(_searchParameter.build(),
          sort: _searchSort,
          page: index + 1,
        ),
        builder: (context, snapshot) {
          if(snapshot.connectionState != ConnectionState.done)
            return loadingBody;

          if(snapshot.error != null || snapshot.data == null) {
            if(snapshot.error is ApiException) {
              if((snapshot.error! as ApiException).message == 'does not exist') {
                return ExceptionPage(
                  onRefresh: () async => setState(() {}), 
                  child: const Center(
                    child: Text('Page doesn\'t exist.'),
                  ),
                );
              }
            }

            // Unknown error
            if(kDebugMode)
              print(snapshot.error);
            
            return ExceptionPage(
              onRefresh: () async => setState(() {}), 
              child: const Center(
                child: Text('Unknown error happened while loading this page.'),
              ),
            );
          }

          final search = snapshot.data!;
          _pages = search.pages;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              childAspectRatio: 9/13,
            ),
            // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //   crossAxisCount: 5,
            //   childAspectRatio: 9/13,
            // ),
            itemBuilder: (context, index) => createGalleryCardWithCallback(updateIfNeeded)(
              context, 
              search.books.elementAt(index),
            ),
            itemCount: search.books.length,
          );
        }, 
      ),
    ),
  ); 

  @override
  Widget build(BuildContext context) {
    if(_pages == null) {
      return Material(
        child: SafeArea(
          child: buildInitial(context),
        ),
      );
    }
    // Look for num of pages and create page or create page.
    return buildView(context);
  }

  Widget get loadingBody => Center(
    child: Column(
      children: [
        const CircularProgressIndicator(),
        FutureBuilder(
          future: Future<void>.delayed(const Duration(seconds: 3)), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done)
              return FilledButton(
                onPressed: () {
                  if (context.mounted)
                    GoRouter.of(context).refresh();
                }, 
                child: const Text('Refresh'),
              );
            
            return const SizedBox.shrink();
          },
        ),
      ],
    ),
  ); 

  

  Drawer get drawer => Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          child: Text(packageInfo.appName),
        ),
        ListTile(
          title: const Text('Favorites'),
          onTap: () async {
            GoRouter.of(context).push('/favorites');
          },
        ),
        ListTile(
          title: const Text('Select tags'),
          onTap: () async {
            GoRouter.of(context).push('/tags')
              .then((_) => updateIfNeeded());
          },
        ),
        ListTile(
          title: const Text('History'),
          onTap: () async {
            GoRouter.of(context).push('/history');
          },
        ),
        ListTile(
          title: const Text('Settings'),
          onTap: () async {
            GoRouter.of(context).push('/settings')
              .then((_) => GoRouter.of(context)
                .pushReplacement('/search?query=${widget.query}&page=$_page&pages=$_pages'),
              );
          },
        ),
      ],
    ),
  );

  Future<void> search(String query) async {
    if(kDebugMode)
      print('Homepage search with query: $query');
    final id = int.tryParse(query);
    if(id != null)
      GoRouter.of(context).push('/book/$id');
    else
      GoRouter.of(context).go('/search?query=${_searchBarController.text}&page=1');
  }

  AppBar get appBar => AppBar(
    title: TextField(
      controller: _searchBarController,
      onSubmitted: search,
    ),
    actions: [
      IconButton(
        onPressed: () async {
          search(_searchBarController.text);
        },
        icon: const Icon(Icons.search),
      ),
      PopupMenuButton<SearchSort>(
        icon: const Icon(Icons.sort),
        onSelected: (_selectedSearchSort) async {
          preferences.setSearchSort(_selectedSearchSort).then((value) => 
            GoRouter.of(context).pushReplacement('/search'.addQuery({
              'query': _searchParameter.query,
              'page': 1,
            }), 
              extra: {
                'include': _searchParameter.includedTags,
                'exclude': _searchParameter.excludedTags,
              },
            ),
          );
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: SearchSort.recent,
            enabled: _searchSort != SearchSort.recent,
            child: const Text('Recent'),
          ),
          PopupMenuItem(
            value: SearchSort.popular,
            enabled: _searchSort != SearchSort.popular,
            child: const Text('Popular'),
          ),
          PopupMenuItem(
            value: SearchSort.popularToday,
            enabled: _searchSort != SearchSort.popularToday,
            child: const Text('Popular today'),
          ),
          PopupMenuItem(
            value: SearchSort.popularWeek,
            enabled: _searchSort != SearchSort.popularWeek,
            child: const Text('Popular week'),
          ),
          PopupMenuItem(
            value: SearchSort.popularMonth,
            enabled: _searchSort != SearchSort.popularMonth,
            child: const Text('Popular month'),
          ),
        ],
      ),
    ],
  );

  Future<void> openBook(Book book) async {
    if(kDebugMode)
      print('b');
    GoRouter.of(context).push('/book/${book.id}', extra: book)
    .then((_) async {
      if (kDebugMode)
        print('a');
      updateIfNeeded();
    });
  }

  Future<void> updateIfNeeded() async {
    final includedTagsIds = storage.selectedTagsBox.values
      .where((tag) => tag.state == TagState.included).map((tag) => tag.id)
      .toSet();
    final excludedTagsIds = storage.selectedTagsBox.values
      .where((tag) => tag.state == TagState.excluded).map((tag) => tag.id)
      .toSet(); 
    
    final equalsIncluded = const SetEquality<int>().equals(
      _searchParameter.includedTags.map((tag) => tag.id).toSet(), 
      includedTagsIds,
    );

    final equalsExcluded = const SetEquality<int>().equals(
      _searchParameter.excludedTags.map((tag) => tag.id).toSet(),
      excludedTagsIds,
    );

    if(!equalsIncluded || !equalsExcluded) {
      GoRouter.of(context).pushReplacement('/search'.addQuery({
        'query': widget.query,
      }),);
    }
  }

}
