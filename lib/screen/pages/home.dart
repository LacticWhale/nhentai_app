import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/data_model.dart';
import 'package:nhentai/nhentai.dart';
import 'package:preload_page_view/preload_page_view.dart';

import '../../api.dart';
import '../../functions/create_gallery_card.dart';
import '../../main.dart';
import '../../widgets/my_navigation_bar.dart';
import '../../widgets/selector.dart';
import '../../widgets/tag_block.dart';
import '../webview/nhentai.net.dart';
import 'book.dart';
import 'favorites.dart';
import 'history.dart';
import 'settings.dart';
import 'tags.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    this.query = '',
    this.page = 1,
    this.searchSort = SearchSort.popular,
    this.pages,
    this.includedTags,
    this.excludedTags,
    this.drawer = true,
    super.key,
  });

  final SearchSort searchSort;
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
      ..add(EnumProperty<SearchSort>('searchSort', searchSort))
      ..add(IntProperty('pages', pages))
      ..add(IntProperty('page', page))
      ..add(StringProperty('query', query))
      ..add(IterableProperty<Tag>('tagsList', includedTags))
      ..add(IterableProperty<Tag>('excludedTags', excludedTags))
      ..add(DiagnosticsProperty<bool>('drawer', drawer));
  }
}

class _NewHomePageState extends State<HomePage> {
  late int _page;
  int? _pages;

  late TextEditingController _searchBarController;
  late PreloadPageController _pageController;
  late MyNavigationBarController _appNavBarController;

  late List<Tag> _includedTags;
  late List<Tag> _excludedTags;

  String get query => '${widget.query == '' ? '*' : widget.query}${_includedTags.isNotEmpty ? ' ${_includedTags.join(' ')}' : '' }${_excludedTags.isNotEmpty ? ' ${_excludedTags.map((e) => '-$e').join(' ')}' : ''}';
  
  @override
  void initState() {
    _page = widget.page;

    final selectedTags = storage.selectedTagsBox.values;

    _includedTags = List.from(widget.includedTags 
      ?? selectedTags.where((tag) => tag.state == TagState.included),);
    _excludedTags = List.from(widget.excludedTags 
      ?? selectedTags.where((tag) => tag.state == TagState.excluded),);

    if (kDebugMode) 
      print('${_includedTags.hashCode} ${_excludedTags.hashCode}');
    

    _searchBarController = TextEditingController(
      text: widget.query,
    );
    _pageController = PreloadPageController(
      initialPage: _page - 1,
      viewportFraction: 0.99,
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

  Widget buildInitial(BuildContext context) => FutureBuilder<Search?>(
    // ignore: discarded_futures
    future: api.searchSinglePage(query,
      sort: widget.searchSort,
      page: widget.page,
    ),
    builder: (context, snapshot) {
      if(snapshot.connectionState != ConnectionState.done)
        return loading;

      if(snapshot.error != null || snapshot.data == null) 
        return Material(
          child: SafeArea(
            child: Scaffold(
              appBar: AppBar(),
              drawer: widget.drawer ? drawer : null,
              body: Center(
                child: Card(
                  child: TextButton(
                    child: const Text('Update cookies.'),
                    onPressed: () async {
                      (api.client as HttpClientWithCookies)
                        .clearCookies()
                        .then((value) => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const NHentaiWebView(),
                          ),
                        ).then((value) => setState(() { })),);
                    },
                  ),
                ),
              ),
            ),
          ),
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
    bottomNavigationBar: bottomNavigationBar,
    body: PreloadPageView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      onPageChanged: (value) => _appNavBarController.changeCurrentPage(_page = value + 1),
      controller: _pageController,
      preloadPagesCount: 3,
      itemCount: _pages! - 1,
      itemBuilder: (context, index) => FutureBuilder<Search?>(
        // ignore: discarded_futures
        future: api.searchSinglePage(query,
          sort: widget.searchSort,
          page: index + 1,
        ),
        builder: (context, snapshot) {
          if(snapshot.connectionState != ConnectionState.done)
            return loadingBody;

          if(snapshot.error != null || snapshot.data == null) {
            // if(snapshot.error != null && snapshot.error is APIException) {
            //   // debugPrint((snapshot.error! as APIException).message);
            //   // if((snapshot.error! as APIException).message == 'does not exist') {
            //   //   debugPrint('${index + 2}');
            //   //   _pageController.jumpToPage(index + 2);
            //   // }
            // }
            // TODO: report error.
            debugPrint(snapshot.error.toString());
            return const Material(
              child: Center(
                child: Text('Page doesn\'t exist.'),
              ),
            );
          }

          final search = snapshot.data!;
          _pages = search.pages;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 9/13,
            ),
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

  Widget get loadingBody => const Center(
    child: CircularProgressIndicator(),
  ); 

  Scaffold get loading => Scaffold(
    appBar: appBar,
    drawer: drawer,
    body: loadingBody,
  );


  Drawer get drawer => Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          child: Text('nhentai_app'),
        ),
        ListTile(
          title: const Text('Favorites'),
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const FavoritesPage(), 
              ), 
            );
          },
        ),
        ListTile(
          title: const Text('Select tags'),
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const TagSelectorPage(), 
              ), 
            ).then((_) => updateIfNeeded());
          },
        ),
        ListTile(
          title: const Text('History'),
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const HistoryPage(), 
              ), 
            );
          },
        ),
        ListTile(
          title: const Text('Settings'),
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const SettingsPage(),
              ),
            ).then((_) => Navigator.pushReplacement(context, 
              MaterialPageRoute<void>(builder: (context) => HomePage(
                query: widget.query,
                page: _page,
                pages: _pages,
                searchSort: widget.searchSort,
              ),),
            ),);
          },
        ),
      ],
    ),
  );

  AppBar get appBar => AppBar(
    title: TextField(
      controller: _searchBarController,
    ),
    actions: [
      IconButton(
        onPressed: () async {
          Navigator.pushReplacement(context, 
            MaterialPageRoute<void>(builder: (context) => HomePage(
                query: _searchBarController.text,
                page: 1,
                searchSort: widget.searchSort,
              ),
            ),
          );
        },
        icon: const Icon(Icons.search),
      ),
      PopupMenuButton<SearchSort>(
        icon: const Icon(Icons.sort),
        onSelected: (_selectedSearchSort) async {
          // preferences.setSearchSort(_selectedSearchSort).then((value) => 
            Navigator.pushReplacement(context, 
              MaterialPageRoute<void>(builder: (context) => HomePage(
                  query: widget.query,
                  page: 1,
                  searchSort: _selectedSearchSort,
                  includedTags: widget.includedTags,
                  excludedTags: widget.excludedTags,
                ),
              ),
            // ),
          );
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: SearchSort.recent,
            enabled: widget.searchSort != SearchSort.recent,
            child: const Text('Recent'),
          ),
          PopupMenuItem(
            value: SearchSort.popular,
            enabled: widget.searchSort != SearchSort.popular,
            child: const Text('Popular'),
          ),
          PopupMenuItem(
            value: SearchSort.popularToday,
            enabled: widget.searchSort != SearchSort.popularToday,
            child: const Text('Popular today'),
          ),
          PopupMenuItem(
            value: SearchSort.popularWeek,
            enabled: widget.searchSort != SearchSort.popularWeek,
            child: const Text('Popular week'),
          ),
          PopupMenuItem(
            value: SearchSort.popularMonth,
            enabled: widget.searchSort != SearchSort.popularMonth,
            child: const Text('Popular month'),
          ),
        ],
      )
    ],
  );

  MyNavigationBar? _bottomNavigationBar;
  MyNavigationBar get bottomNavigationBar => _bottomNavigationBar ??= MyNavigationBar(
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
            // onJump: (index) => setState(() => _page = index),
            onJump: (page) => _pageController.jumpToPage(page),
          ),
        ),
      ),
    ),
    onRight: () async {
      if(_page < _pages!) 
        _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.decelerate);
    },
  );

  Future<void> openBook(Book book) async {
    if(kDebugMode)
      print('b');
    Navigator.push(context,
      MaterialPageRoute<void>(
        builder: (context) =>
          BookPage(book: book),
      ),
    ).then((_) async {
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
      _includedTags.map((tag) => tag.id).toSet(), 
      includedTagsIds,);

    final equalsExcluded = const SetEquality<int>().equals(
        _excludedTags.map((tag) => tag.id).toSet(),
        excludedTagsIds,);

    if(!equalsIncluded || !equalsExcluded) {
      Navigator.pushReplacement(context, 
        MaterialPageRoute<void>(builder: (context) => HomePage(
          query: widget.query,
        ),),
      );
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('query', query));
  }

}
