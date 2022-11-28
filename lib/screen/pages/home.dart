import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/data_model.dart';
import 'package:nhentai/nhentai.dart';
import 'package:preload_page_view/preload_page_view.dart';

import '../../api.dart';
import '../../functions/create_gallery_card.dart';
import '../../functions/image_builder.dart';
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
    super.key,
  });

  final SearchSort searchSort;
  final Iterable<Tag>? includedTags;
  final Iterable<Tag>? excludedTags;
  final String query;
  final int page;
  final int? pages;

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
      ..add(IterableProperty<Tag>('excludedTags', excludedTags));
  }
}

class _NewHomePageState extends State<HomePage> {
  late int _page;
  int? _pages;

  late TextEditingController _searchBarController;
  late PreloadPageController _pageController;
  late MyNavigationBarController _appNavBarController;

  late Iterable<Tag> _includedTags;
  late Iterable<Tag> _excludedTags;

  String get query => '${widget.query == '' ? '*' : widget.query}${_includedTags.isNotEmpty ? ' ${_includedTags.join(' ')}' : '' }${_excludedTags.isNotEmpty ? ' ${_excludedTags.map((e) => '-$e').join(' ')}' : ''}';
  
  @override
  void initState() {
    _page = widget.page;

    final selectedTags = storage.selectedTagsBox.values;

    _includedTags = widget.includedTags 
      ?? selectedTags.where((tag) => tag.state == TagState.included);
    _excludedTags = widget.excludedTags 
      ?? selectedTags.where((tag) => tag.state == TagState.excluded);

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

  Widget buildPage(BuildContext context, Search search) => SliverGrid(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 9/13,
    ), 
    delegate: SliverChildBuilderDelegate(
      createCard(search),
      childCount: search.pages,
    ),
  );

  Widget buildInitial(BuildContext context) => FutureBuilder<Search?>(
    // ignore: discarded_futures
    future: api.searchSinglePage(query,
      sort: widget.searchSort,
      page: widget.page,
    ),
    builder: (context, snapshot) {
      if(snapshot.connectionState != ConnectionState.done)
        return loading;

      if(snapshot.error != null) 
        // TODO: report error.
        return tryAgain;

      if(snapshot.data == null)
        // TODO: page is empty???
        return tryAgain;

      final search = snapshot.data!;
      _pages = search.pages;
      _appNavBarController.changePages(_pages!);

      return buildView(context);
    },
  );

  Widget buildView(BuildContext context) => Scaffold(
    appBar: appBar,
    drawer: drawer,
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

          if(snapshot.error != null) {
            // if(snapshot.error != null && snapshot.error is APIException) {
            //   // debugPrint((snapshot.error! as APIException).message);
            //   // if((snapshot.error! as APIException).message == 'does not exist') {
            //   //   debugPrint('${index + 2}');
            //   //   _pageController.jumpToPage(index + 2);
            //   // }
            // }
            // TODO: report error.
            debugPrint(snapshot.error.toString());
            return tryAgainBody;
          }

          if(snapshot.data == null)
            // TODO: page is empty???
            return tryAgainBody;

          final search = snapshot.data!;
          _pages = search.pages;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 9/13,
            ),
            itemBuilder: (context, index) => createGalleryCard(
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

  Widget get tryAgainBody => Center(
    child: Column(
      children: [
        Card(
          child: TextButton(
            child: const Text('Update cookies?'),
            onPressed: () async {
              (api.client as HttpClientWithCookies)
                  .cookieManager
                  .clearCookies()
                  .then((value) {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const NHentaiWebView(),
                  ),
                ).then((value) => setState(() { }),);
              });
            },
          ),
        ),
        Card(
          child: TextButton(
            child: const Text('Reload.'),
            onPressed: () async {
              // Navigator.pushReplacement(context, 
              //   MaterialPageRoute(builder: (context) => HomePage(
              //     query: widget.query,
              //     page: _page,
              //     searchSort: widget.searchSort,
              //   ),
              // ),);
              setState(() {
                _page = _page;
                _pages = _pages;
              });
            },
          ),
        ),
      ],
    ),
  );

  Scaffold get tryAgain => Scaffold(
    appBar: appBar,
    drawer: drawer,
    body: tryAgainBody,
    // bottomNavigationBar: bottomNavigationBar,
  );

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
            ).then((_) {
              final includedTags = storage.selectedTagsBox.values
                .where((tag) => tag.state == TagState.included);
              final excludedTags = storage.selectedTagsBox.values
                .where((tag) => tag.state == TagState.excluded);

              final newRoute = MaterialPageRoute<void>(
                builder: (context) => HomePage(
                  query: widget.query,
                  includedTags: includedTags,
                  excludedTags: excludedTags,
                ),
              );
              
              Navigator.pushReplacement(context, newRoute);
            });
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

  Widget Function(BuildContext context, int index) createCard(
    Search search,
  ) => (context, index) => GestureDetector(
    onTap: () async {
      Navigator.of(context).push(
        MaterialPageRoute<BookPage>(
          builder: (context) =>
              BookPage(book: search.books.elementAt(index)),
        ),
      );
    },
    child: Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(
        left: 10,
        right: 10,
        top: 20,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            child: CachedNetworkImage(
              alignment: Alignment.center,
              imageUrl: search.books
                  .elementAt(index)
                  .cover
                  .getUrl(api: api)
                  .toString(),
              httpHeaders: MyApp.headers,
              progressIndicatorBuilder:
                  (context, url, downloadProgress) => Center(
                child: CircularProgressIndicator(
                    value: downloadProgress.progress,),
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error),
              imageBuilder: blurredImageBuilder,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 1 / 5,
              child: Container(
                alignment: Alignment.center,
                color: Colors.black.withAlpha(120),
                padding: const EdgeInsets.all(8),
                child: Text(
                  search.books.elementAt(index).title.pretty,
                  overflow: TextOverflow.fade,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('query', query));
  }

}
