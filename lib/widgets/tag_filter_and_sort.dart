import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'tag_block.dart';

enum TagSortType {
  count('Count'),
  name('Name');

  const TagSortType(this.title);
  final String title;

  static TagSortType get global => 
    values[storage.getInt('$TagSortType', defaultValue: 0) ?? 0]; 

  static Future<void> setGlobal(TagSortType value) async =>
    storage.setInt('$TagSortType', value.index);
}

enum TagOrderType {
  desc('Descending'),
  asc('Ascending');

  const TagOrderType(this.title);
  final String title;

  
  static TagOrderType get global => 
    values[storage.getInt('$TagOrderType', defaultValue: 0) ?? 0]; 

  static Future<void> setGlobal(TagOrderType value) async =>
    storage.setInt('$TagOrderType', value.index);
}

class TagsFilterAndSortController extends ChangeNotifier {
  TagsFilterAndSortController();

  TagSortType? type;
  TagOrderType? order;

  int Function(TagWithState a, TagWithState b) get compareFunction =>
    <List<int Function(TagWithState a, TagWithState b)>>[
      [
        (a, b) => -a.count.compareTo(b.count),
        (a, b) => a.count.compareTo(b.count),
      ],
      [
        (a, b) => -a.name.compareTo(b.name),
        (a, b) => a.name.compareTo(b.name),
      ],
    ][type?.index ?? TagSortType.global.index][order?.index ?? TagOrderType.global.index];


  static int Function(TagWithState a, TagWithState b) get globalCompareFunction =>
    <List<int Function(TagWithState a, TagWithState b)>>[
      [
        (a, b) => -a.count.compareTo(b.count),
        (a, b) => a.count.compareTo(b.count),
      ],
      [
        (a, b) => -a.name.compareTo(b.name),
        (a, b) => a.name.compareTo(b.name),
      ],
    ][TagSortType.global.index][TagOrderType.global.index];

  static Future<void> changeGlobalValue({
    TagSortType? newType,
    TagOrderType? newOrder,
  }) async {
    if(newType != null)
      await TagSortType.setGlobal(newType);
    if(newOrder != null)
      await TagOrderType.setGlobal(newOrder);
  }

  Future<void> changeValue({
    TagSortType? newType,
    TagOrderType? newOrder,
  }) async {
    if(newType != null)
      await TagSortType.setGlobal(type = newType);
    if(newOrder != null)
      await TagOrderType.setGlobal(order = newOrder);

    notifyListeners();
  }
}

class TagsFilterAndSort extends StatefulWidget {
  const TagsFilterAndSort({
    required this.controller,
    super.key,
  });

  final TagsFilterAndSortController controller;

  @override
  State<StatefulWidget> createState() => _TagsFilterAndSortState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(DiagnosticsProperty<TagsFilterAndSortController>('controller', controller));
  }

}

class _TagsFilterAndSortState extends State<TagsFilterAndSort> {
  TagSortType? _tagsSortType;
  TagOrderType? _tagsOrderType;

  @override
  void initState() {
    _tagsOrderType = TagOrderType.global;
    _tagsSortType = TagSortType.global;

    super.initState();

  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filter & sort', style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),),
        const SizedBox(height: 10,),
        const Text('Sort by: ', style: TextStyle(
          color: Colors.grey,
        ),),
        ...TagSortType.values.map((e) => ListTile(
          title: Text(e.title),
          leading: Radio<TagSortType>(
            value: e,
            groupValue: _tagsSortType,
            onChanged: (value) async {
              TagSortType.setGlobal(value ?? TagSortType.count);
              setState(() {
                _tagsSortType = value;
              });
            },
          ),
        ),),
        const Text('Order: ', style: TextStyle(
          color: Colors.grey,
        ),),
        ...TagOrderType.values.map((e) => ListTile(
          title: Text(e.title),
          leading: Radio<TagOrderType>(
            value: e,
            groupValue: _tagsOrderType,
            onChanged: (value) async {
              TagOrderType.setGlobal(value ?? TagOrderType.desc);
              setState(() {
                _tagsOrderType = value;
              });
            },
          ),
        ),),
      ],
    ),
  );

}
