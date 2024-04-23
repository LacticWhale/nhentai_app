import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nhentai/nhentai_prefixed.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:preload_page_view/preload_page_view.dart';

import '../../api.dart';
import '../../app.dart';
import '../../functions/image_builder.dart';
import '../../main.dart';
import '../../widgets/my_navigation_bar.dart';
import '../../widgets/selector.dart';

class PageViewer extends StatefulWidget {
  const PageViewer({
    required this.book,
    required this.initPageIndex, 
    super.key, 
  });

  final NHentaiBook book;
  final int initPageIndex;

  @override
  State<StatefulWidget> createState() => _PageViewerState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<NHentaiBook>('book', book))
      ..add(IntProperty('initPage', initPageIndex));
  }
}

class _PageViewerState extends State<PageViewer> {
  final _transformationController = TransformationController();
  late PreloadPageController _pageController;
  late MyNavigationBarController _appNavBarController;

  late int _page;
  late int _pages;

  bool canScroll = true;

  @override
  void initState() {
    _page = widget.initPageIndex;
    _pages = widget.book.pages.length;
    
    _pageController = PreloadPageController(initialPage: _page);
    _appNavBarController = MyNavigationBarController(
      initialPage: _page + 1,
      pages: _pages,
    );

    super.initState();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pageController.dispose();
    _appNavBarController.dispose();

    super.dispose();
  }

  Future<void> nextPage() async {
    if(_page < _pages)
      _pageController.nextPage(
        duration: const Duration(milliseconds: 200), 
        curve: Curves.decelerate,
      );
  }

  Future<void> prevPage() async {
    if(_page > 1) 
      _page++;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 200), 
        curve: Curves.decelerate,
      );
  }

  static const MethodChannel _pathChannel = MethodChannel('azura.moe/paths');
  
  static const MethodChannel _clipboardChannel = MethodChannel('azura.moe/clipboard');

  Future<File?> getImage([int? page]) async {
    final storage = await Permission.storage.request();
    final manage = await Permission.manageExternalStorage.request();

    if (!storage.isGranted)
      return null;

    if(!manage.isGranted)
      return null;

    final _page = page ?? _pageController.page?.round() ?? 1;

    return DefaultCacheManager().getSingleFile(
      widget.book.pages.elementAt(_page).getUrl(api: api).toString(),
    );
  }

  Future<void> copyPage([int? page]) async {
    final image = await getImage(page);
    if(image == null)
      return;
    
    if(!Platform.isAndroid) {
      if(Platform.isWindows || Platform.isLinux || Platform.isMacOS)
        Pasteboard.writeFiles([image.absolute.path]);
      else 
        Pasteboard.writeImage(await image.readAsBytes());
    } else 
      _pathChannel.invokeMethod('copyImage', [
        (await image.readAsBytes()).toList(),
      ]);

  }

  Future<void> downloadPage([int? page]) async {
    final image = await getImage(page);
    if(image == null)
      return;
    
    final Directory savePath;
    if (Platform.isAndroid) 
      savePath = Directory(
        join(
          await _pathChannel.invokeMethod<String>('getDocumentDirectory') ?? '',
          packageInfo.appName,
        ),
      );
    else if (Platform.isIOS)
      savePath = await getApplicationDocumentsDirectory();
    else 
      savePath = (await getDownloadsDirectory())!;

    final book = widget.book;
    final path = join(
      savePath.path,  
      '${book.id} - ${book.title.pretty}',
      book.pages.elementAt(_page).filename,
    );

    await (File(path)..createSync(recursive: true))
      .openWrite().addStream(image.openRead());
    
    await Clipboard.setData(ClipboardData(text: await image.openRead().transform(base64.encoder).join()));
  }

  @override
  Widget build(BuildContext context) => Material(
    child: SafeArea(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'copy': 
                    
                    break;
                    case 'save':
                      downloadPage();
                    break;
                  }
                }, 
                itemBuilder: (context) => [
                  if(!Platform.isIOS)
                    const PopupMenuItem(
                      value: 'save',
                      child: Text('Save to gallery'),
                    ),
                  const PopupMenuItem(
                    value: 'copy',
                    child: Text('Copy to clipboard'),
                  )
                ],
                icon: const Icon(Icons.more_vert),
              ),
            )
          ],
        ),
        body: PreloadPageView.builder(
          controller: _pageController,
          onPageChanged: (page) => _appNavBarController.changeCurrentPage(page + 1),
          physics: canScroll 
            ? const ScrollPhysics() 
            : const NeverScrollableScrollPhysics(),
          itemCount: _pages,
          preloadPagesCount: 3,
          itemBuilder: buildPage,
        ),
        bottomNavigationBar: MyNavigationBar(
          controller: _appNavBarController,
          onLeft: prevPage, 
          onText: () async => showDialog<void>(
            context: context,
            builder: (context) => Selector(
              pages: _pages,
              page: _page,
              onJump: (index) {
                _pageController.jumpToPage(_page = index);
              },
            ),
          ),
          onRight: nextPage,
        ),
      ),
    ),
  );

  Widget buildPage(BuildContext context, int page) => Center(
    child: GestureDetector(
      onDoubleTapDown: (details) {
        if (kDebugMode) {
          print(_transformationController.value);
          print(details.globalPosition);
          print(details.localPosition);
        }
        setState(() {
          _transformationController.value.setFrom(Matrix4.identity());
        });
      },
      onTapUp: (details) async {
        final x = details.globalPosition.dx;
        final width = MediaQuery.of(context).size.width;

        if (x/width < 0.3) 
          prevPage();
        else 
          nextPage();
      },
      child: InteractiveViewer(
        onInteractionEnd: (details) {
          if(mounted)
            setState(() {
              canScroll = _transformationController.value.isIdentity();
            });
        },
        transformationController: _transformationController,
        child: CachedNetworkImage(
            imageUrl: widget.book.pages.elementAt(page).getUrl(api: api).toString(),
            httpHeaders: MyApp.headers,
            progressIndicatorBuilder: (context, url, downloadProgress) => 
              Center(
                child: CircularProgressIndicator(value: downloadProgress.progress),
              ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            imageBuilder: blurredImageBuilder,
          ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('canScroll', canScroll));
  }
}
