import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nhentai/data_model.dart';
import 'package:nhentai/data_model_prefixed.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';

import '../../api.dart';
import '../../functions/image_builder.dart';
import '../../main.dart';
import '../../widgets/tag_block.dart';
import 'home.dart';
import 'page_viewer.dart';

class BookPage extends StatefulWidget {
  const BookPage({
    required this.book,
    super.key,
  });

  final NHentaiBook book;

  @override
  State<StatefulWidget> createState() => _BookPageState();
  
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<NHentaiBook>('book', book));
  }
}

class _BookPageState extends State<BookPage> {
  bool _wrapEnglish = false;
  bool _wrapJapanese = false;
  
  List<Comment>? _comments;
  
  bool _commentsLoaded = false;

  bool get _isFavorite => storage.favoriteBooksBox.containsKey(widget.book.id);

  @override
  Widget build(BuildContext context) => Material(
      child: SafeArea(
        child: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              if(_isFavorite)
                storage.favoriteBooksBox.delete(widget.book.id);
              else 
                storage.favoriteBooksBox.put(widget.book.id, widget.book);

              setState(() { });
            },
            child: Icon(Icons.favorite, color: _isFavorite ? Colors.pink : Colors.grey, ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(widget.book.title.pretty),
                floating: true,
                actions: [
                  IconButton(
                    onPressed: () async => Share.share('${widget.book.title.pretty}\nhttps://nhentai.net/g/${widget.book.id}'),
                    icon: const Icon(Icons.share),
                  ),
                  IconButton(
                    onPressed: () async {
                      await preferences.setPagesPerRow(preferences.pagesPerRow % 4 + 1);
                      setState(() { });
                    },
                    icon: const Icon(Icons.grid_view_sharp),
                  )
                ],
              ),
              buildDescription(context),
              if(preferences.pagesPerRow == 1)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => GestureDetector(
                        onTap: () async {
                          Navigator.push(
                            context, 
                            MaterialPageRoute<void>(
                              builder: (context) => PageViewer(
                                book: widget.book, 
                                initPageIndex: index,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // TODO: Appropriately size boxes to fit image
                              // It's 22:52. My brain already shuted down to figure that out.
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 
                                    (widget.book.pages.elementAt(index).height?.toDouble() ?? 1) 
                                    * MediaQuery.of(context).size.width 
                                    / (widget.book.pages.elementAt(index).width?.toDouble() ?? 1),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: widget.book.pages.elementAt(index)
                                    .getUrl(api: api).toString(),
                                  httpHeaders: MyApp.headers,
                                  progressIndicatorBuilder: (context, url, downloadProgress) => Center(
                                    child: CircularProgressIndicator(value: downloadProgress.progress),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8), 
                                child: Text('${index + 1}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    childCount: widget.book.pages.length,
                  ),
                )
              else 
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: preferences.pagesPerRow,
                    childAspectRatio: 9/16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    createPageCard,
                    childCount: widget.book.pages.length,
                  ),
                ),
              if(!_commentsLoaded)
                SliverList(
                  delegate: SliverChildListDelegate([
                    ElevatedButton(
                      onPressed: () async {
                        _comments = await api.getComments(widget.book.id);
                        _commentsLoaded = true;
                        setState(() {
                          
                        });
                      },
                      child: const Text('Load comments'),
                    )
                  ]),
                )
              else
                buildCommentSection(context, _comments!),
            ],
          ),
        ),
      ),
    );

  SliverList buildDescription(BuildContext context) => SliverList(
    delegate: SliverChildListDelegate([
      if (widget.book.title.english != null)
        GestureDetector(
          onTap: () => setState(() {
            _wrapEnglish = !_wrapEnglish;
          }),
          onLongPress: () async {
            Clipboard.setData(ClipboardData(text: widget.book.title.english)).then((_){
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('English title copied to your clipboard!'),
                  backgroundColor: Colors.white60,
                ),);
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 8.0), 
            child: Text(widget.book.title.english!,
              // softWrap: wrapEnglish,
              overflow: TextOverflow.ellipsis,
              maxLines: _wrapEnglish ? 20 : 1, 
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      if (widget.book.title.japanese != null)
        GestureDetector(
          onTap: () => setState(() {
            _wrapJapanese = !_wrapJapanese;
          }),
          onLongPress: () async {
            Clipboard.setData(ClipboardData(text: widget.book.title.japanese)).then((_){
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('Japanese title copied to your clipboard!'),
                  backgroundColor: Colors.white60,
                ),);
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 8.0), 
            child: Text(widget.book.title.japanese!,
              overflow: TextOverflow.ellipsis,
              maxLines: _wrapJapanese ? 20 : 1, 
              style: TextStyle(
                fontSize: (widget.book.title.english == null) ? 20 : 17,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, top: 8.0),
        child: GestureDetector(
          onTap: () async {
            Clipboard.setData(ClipboardData(text: widget.book.id.toString())).then((_){
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('Book id copied to your clipboard!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.white60,
                ),);
            });
          },
          onLongPress: () async {
            Clipboard.setData(ClipboardData(text: widget.book.title.pretty)).then((_){
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('Pretty title copied to your clipboard!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.white60,
                ),);
            });
          },
          child: Row(
            children: [
              const Text('#', 
                style: TextStyle(
                  color: Color.fromARGB(0xff, 0x66, 0x66, 0x66),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(widget.book.id.toString(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              )
            ],
          ),
        ),
      ),
      ...{
        'Parodies' : widget.book.tags.parodies,
        'Characters': widget.book.tags.characters,
        'Tags': widget.book.tags.tags,
        'Artists': widget.book.tags.artists,
        'Groups': widget.book.tags.groups,
        'Languages': widget.book.tags.languages,
        'Categories': widget.book.tags.categories,
      }.entries.map<Widget?>((entry) => entry.value.isNotEmpty 
        ? Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${entry.key}: ',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              ...(entry.value.toList()..sort((a, b) => -a.count.compareTo(b.count)))
                .map((tag) => GestureDetector(
                onLongPress: () async {
                  preferences.toggleTag(tag).then((state) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text.rich(TextSpan(
                          text: 'Tag ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text: tag.name,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: state == TagState.none 
                                ? 'unselected.'
                                : state == TagState.included
                                  ? 'included.'
                                  : 'excluded.',
                            ),
                          ],
                        ),),
                        backgroundColor: Colors.white60,
                      ),);
                  });
                },
                onTap: () async {
                  Navigator.push(context, 
                    MaterialPageRoute<void>(
                      builder: (context) => HomePage(
                        drawer: false,
                        includedTags: [
                          TagWithState(tag: tag, state: TagState.included),
                        ],
                      ),
                    ),
                  );
                },
                child: TagBlock(
                  tag: TagWithState(
                    tag: tag,
                    state: TagState.none, 
                  ),
                ),
              ),),
            ],
          ),
        ) : null,).whereType(),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
        child: Text.rich(TextSpan(
          text: 'Pages: ',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ), 
          children: [
            TextSpan(
              text: widget.book.pages.length.toString(), 
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),),
      ),
    ],),
  );

  Widget buildCommentSection(BuildContext context, List<Comment> comments) => SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) => Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              alignment: Alignment.topLeft,
              margin: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CachedNetworkImage(
                    alignment: Alignment.center,
                    imageUrl: join(api.hosts.image.getUri().toString(), 'avatars', comments.elementAt(index).author.avatarFilename),
                    httpHeaders: MyApp.headers,
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) => Center(
                      child: CircularProgressIndicator(
                          value: downloadProgress.progress,),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                    imageBuilder: (context, imageProvider) => CircleAvatar(
                      foregroundImage: imageProvider,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(comments.elementAt(index).author.username),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(DateTime.now().difference(comments.elementAt(index).date).toString()),
                  )
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.all(16.0),
              child: Text(comments.elementAt(index).body),
            ),
          ],
        ),
      ),
      childCount: comments.length,
    ),
  );

  Widget createPageCard(BuildContext context, int index) => GestureDetector(
    onTap: () async {
      Navigator.push(context, MaterialPageRoute<void>(builder:(context) => PageViewer(book: widget.book, initPageIndex: index),));
    },
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Container(
            alignment: Alignment.center, 
            child: CachedNetworkImage(
              alignment: Alignment.center,
              imageUrl: widget.book.pages.elementAt(index)
                .getUrl(api: api).toString(),
              httpHeaders: MyApp.headers,
              progressIndicatorBuilder: (context, url, downloadProgress) =>
                Center(
                  child: CircularProgressIndicator(value: downloadProgress.progress),
                ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              imageBuilder: blurredImageBuilder,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
                  width: double.maxFinite,
                  // color: Colors.black38,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text((index + 1).toString(),),
                    ),
                  ),
                ),
              // ),
            ),
        ],
      ),
    ),
  );
}
