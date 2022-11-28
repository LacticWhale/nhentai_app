import 'package:collection/collection.dart';
import 'package:dynamic_layouts/dynamic_layouts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/data_model.dart';
import 'package:ordered_set/ordered_set.dart';

import '../../main.dart';
import '../../widgets/tag_block.dart';
import '../../widgets/tag_filter_and_sort.dart';

OrderedSet<TagWithState> selectedTags = OrderedSet(TagsFilterAndSortController.globalCompareFunction);

class TagSelectorPage extends StatefulWidget {
  const TagSelectorPage({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _TagSelectorPageState();
}

const data = {
  'Selected': null,
  'Tags': TagType.tag,
  'Characters': TagType.character,
  'Artists': TagType.artist,
  'Parodies': TagType.parody,
  'Languages': TagType.language,
  'Groups': TagType.group,
};

class NamedNotifier {
  final _listeners = <String, Function>{};

  void addListener(String name, Function cb) {
    _listeners.addAll({
      name: cb,
    });
  }

  void removeListener(String name) {
    _listeners.remove(name);
  }

  void notifyListeners() {
    for (final cb in _listeners.values) {
      cb();
    }
  }
}

class _TagSelectorPageState extends State<TagSelectorPage> with TickerProviderStateMixin {
  final TextEditingController _textEditingController = TextEditingController();
  final NamedNotifier _namedNotifier = NamedNotifier();
  late TagsFilterAndSortController _tagsFilterAndSortController;
  late PageController _pageController;
  late TabController _tabController; 

  @override
  void setState(VoidCallback fn) {
    
    super.setState(fn);
  }

  @override
  void initState() {
    _pageController = PageController();
    _tagsFilterAndSortController = TagsFilterAndSortController();

    selectedTags = OrderedSet(_tagsFilterAndSortController.compareFunction);
    selectedTags.addAll(storage.selectedTagsBox.values);

    _textEditingController.addListener(_namedNotifier.notifyListeners);

    _tabController = TabController(length: data.length, vsync: this);

    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _tagsFilterAndSortController.dispose();
    _pageController.dispose();
    _tabController.dispose();

    super.dispose();
  }

  void notifyParent() {
    selectedTags = OrderedSet(_tagsFilterAndSortController.compareFunction);
    selectedTags.addAll(storage.selectedTagsBox.values);
  }

  @override
  Widget build(BuildContext context) => Material(
    child: SafeArea(
      child: Scaffold(
        appBar: _TagsAppBar(
          notifyParent: notifyParent, 
          tagsFilterAndSortController: _tagsFilterAndSortController,
          textEditingController: _textEditingController,
        ),
        body: Column(
          children: [
            TabBar(
              isScrollable: true,
              onTap: (value) => _pageController.jumpToPage(value),
              controller: _tabController,
              tabs: [
                ...data.keys.map((key) => ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 25,
                  ), 
                  child: Center(
                    child: Text(key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) => _tabController.animateTo(value),
                itemCount: data.length,
                itemBuilder: (context, index) => _TagPageView(
                  type: data.values.elementAt(index),
                  tags: selectedTags,
                  title: data.keys.elementAt(index), 
                  compare: _tagsFilterAndSortController.compareFunction,
                  textEditingController: _textEditingController,
                  namedNotifier: _namedNotifier,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

}

class _TagsAppBar extends StatefulWidget implements PreferredSizeWidget {
  const _TagsAppBar({
    required this.tagsFilterAndSortController,
    required this.textEditingController,
    required this.notifyParent,
  });

  final TagsFilterAndSortController tagsFilterAndSortController;
  final TextEditingController textEditingController;
  final void Function() notifyParent;

  @override
  State<StatefulWidget> createState() => _TagsAppBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<TagsFilterAndSortController>('tagsFilterAndSortController', tagsFilterAndSortController))
      ..add(ObjectFlagProperty<void Function()>.has('notifyParent', notifyParent))
      ..add(DiagnosticsProperty<TextEditingController>('textEditingController', textEditingController));
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(56);

}

class _TagsAppBarState extends State<_TagsAppBar> {
  late bool _search;

  @override
  void initState() {
    _search = false;
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) => AppBar(
    title: _search 
      ? TextField(
        controller: widget.textEditingController,
      )
      : const Text('Tag selector'),
    actions: [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () async {
          if(!_search)
            setState(() {
              _search = true;
            });
        },
      ),
      IconButton(
        icon: const Icon(Icons.sort),
        onPressed: () async => showDialog<void>(
          context: context, 
          builder: (context) => TagsFilterAndSort(
            controller: widget.tagsFilterAndSortController,
          ),
        ).then((_) => widget.notifyParent(),),
      ),
    ],
  );

}

class _TagPageView extends StatefulWidget {
  const _TagPageView({
    required this.type,
    required this.tags,
    required this.title,
    required this.compare, 
    required this.textEditingController,
    required this.namedNotifier,
  });

  final TagType? type;
  final OrderedSet<TagWithState> tags;
  final int Function(TagWithState a, TagWithState b) compare;
  final String title;
  final TextEditingController textEditingController;
  final NamedNotifier namedNotifier;

  @override
  State<StatefulWidget> createState() => _TagPageViewState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(IterableProperty<Tag>('tags', tags))
      ..add(EnumProperty<TagType?>('type', type))
      ..add(ObjectFlagProperty<int Function(TagWithState a, TagWithState b)>.has('compare', compare))
      ..add(DiagnosticsProperty<TextEditingController>('textEditingController', textEditingController))
      ..add(DiagnosticsProperty<NamedNotifier>('namedNotifier', namedNotifier));
  }
}

class _TagPageViewState extends State<_TagPageView> {
  late String _query;

  late OrderedSet<TagWithState> _tags;
  late OrderedSet<TagWithState> _selectedTags;
  
  @override
  void setState(VoidCallback fn) {    
    final tags = _query != '' ? widget.tags.where((element) => element.name.contains(_query)) : widget.tags;

    _tags = OrderedSet<TagWithState>(widget.compare)..addAll(tags.where((element) => element.type == widget.type));
    _selectedTags = OrderedSet<TagWithState>(widget.compare)..addAll(tags.where((element) => element.state != TagState.none));
    if(kDebugMode)
      print('${widget.title}: ${widget.tags.length} ${_tags.length} ${_selectedTags.length}.');

    super.setState(fn);
  }

  @override
  void initState() {
    _query = widget.textEditingController.text;
    _tags = OrderedSet<TagWithState>(widget.compare)..addAll(widget.tags.where((element) => element.type == widget.type));
    _selectedTags = OrderedSet<TagWithState>(widget.compare)..addAll(widget.tags.where((element) => element.state != TagState.none));
    if(kDebugMode)
      print('${widget.title}: ${widget.tags.length} ${_tags.length} ${_selectedTags.length}.');

    widget.namedNotifier.addListener(widget.type.toString(), () {
      setState(() {
        _query = widget.textEditingController.text;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    widget.namedNotifier.removeListener(widget.type.toString());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      DynamicSliverGrid(
        gridDelegate: const SliverGridDelegateWithWrapping(
          mainAxisSpacing: 0,
          crossAxisSpacing: 0,
          childCrossAxisExtent: double.infinity,
          childMainAxisExtent: double.infinity,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if(widget.type == null)
              return GestureDetector(
                onTap: () async => toggle(_selectedTags.elementAt(index)),
                child: TagBlock(
                  tag: _selectedTags.elementAt(index),
                ),
              );
            
            // Typed pages
            return GestureDetector( 
              onTap: () async => toggle(_tags.elementAt(index)),
              child: TagBlock(
                tag: _tags.elementAt(index),
              ),
            );
          },
          childCount: widget.type == null ? _selectedTags.length : _tags.length,
        ),
      ),
    ],
  );
  
  Future<void> toggle(TagWithState tag) async {
    final key = storage.selectedTagsBox.toMap().entries.where((e) => e.value.id == tag.id).firstOrNull?.key;
    if(key != null)
      storage.selectedTagsBox.delete(key);
      
    await storage.selectedTagsBox.add(tag..state = tag.state.next());
    setState(() {
      
    });
  }

}
