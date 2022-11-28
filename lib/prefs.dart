import 'dart:async';
import 'dart:io';

// ignore: import_of_legacy_library_into_null_safe
import 'package:binary/binary.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nhentai/data_model.dart';

import 'adapters/tag_adapter.dart';
import 'main.dart';
import 'storage/book.dart';
import 'storage/book_title.dart';
import 'storage/image.dart';
import 'storage/image_type.dart';
import 'storage/tag.dart';
import 'storage/tag_with_state.dart';
import 'widgets/tag_block.dart';

class Preferences {
  Preferences({
    required this.storage,
  });

  Storage storage;
  
  static const kPagesPerRow = 'pages_per_row';
  static const kBlurImages = 'blur_images';
  static const kRecordHistory = 'record_history';
  static const kResetHistoryOnBoot = 'reset_history_on_boot';

  int get pagesPerRow => storage.getInt(kPagesPerRow) ?? 2;
  Future<void> setPagesPerRow(int value) => 
    storage.setInt(kPagesPerRow, value);
  
  bool get blurImages => storage.getBool(kBlurImages) ?? false;
  Future<void> setBlurImage(bool value) => 
    storage.setBool(kBlurImages, value);
  
  bool get recordHistory => storage.getBool(kRecordHistory) ?? true;
  Future<void> setRecordHistory(bool value) => 
    storage.setBool(kRecordHistory, value);
  
  bool get resetHistoryOnBoot => storage.getBool(kResetHistoryOnBoot) ?? false;
  Future<void> setResetHistoryOnBoot(bool value) => 
    storage.setBool(kResetHistoryOnBoot, value);
  
}

class Storage implements CacheProvider {
  static const _favoriteBooks = 'favorite_books';
  static const _bookHistory = 'book_history';

  static const _selectedTags = 'selected_tags';

  static const _bools = 'bools';
  static const _doubles = 'doubles';
  static const _integers = 'integers';
  static const _strings = 'strings';

  late Box<Book> favoriteBooksBox;
  late Box<Book> booksHistoryBox;

  late Box<TagWithState> selectedTagsBox;

  late Box<bool> _boolBox;
  late Box<double> _doubleBox;
  late Box<int> _intBox;
  late Box<String> _stringBox;

  @override
  bool containsKey(String key) => 
    _boolBox.containsKey(key) || 
    _doubleBox.containsKey(key) ||
    _intBox.containsKey(key) ||
    _stringBox.containsKey(key); 
  

  @override
  bool? getBool(String key, {bool? defaultValue}) =>
    _boolBox.get(key, defaultValue: defaultValue);

  @override
  double? getDouble(String key, {double? defaultValue}) =>
    _doubleBox.get(key, defaultValue: defaultValue);

  @override
  int? getInt(String key, {int? defaultValue}) =>
    _intBox.get(key, defaultValue: defaultValue);

  @override
  String? getString(String key, {String? defaultValue}) =>
    _stringBox.get(key, defaultValue: defaultValue);

  @override
  Set<String> getKeys() => {
    ..._boolBox.keys.cast(),
    ..._doubleBox.keys.cast(),
    ..._intBox.keys.cast(),
    ..._stringBox.keys.cast(),
  };

  @override
  T? getValue<T>(String key, {T? defaultValue}) {
    if(T == bool)
      return getBool(key, defaultValue: defaultValue as bool?) as T?;
    else if(T == double)
      return getDouble(key, defaultValue: defaultValue as double?) as T?;
    else if(T == int)
      return getInt(key, defaultValue: defaultValue as int?) as T?;
    else if(T == String)
      return getString(key, defaultValue: defaultValue as String?) as T?;
    else
      throw Exception('Unsupported type.');
  }

  @override
  Future<void> init() async {
    await Hive.initFlutter();

    TagAdapter().registerForId(1);  
    const AdapterForList<Tag>().registerForId(2);

    Hive
      ..registerAdapter(HiveTagWithStateAdapter())
      ..registerAdapter(HiveBookTitleAdapter())
      ..registerAdapter(HiveImageTypeAdapter())
      ..registerAdapter(HiveImageAdapter())
      ..registerAdapter(HiveBookAdapter())
      ..registerAdapter(HiveTagAdapter());
    
    favoriteBooksBox = await Hive
      .openBox<Book>(Storage._favoriteBooks);
    booksHistoryBox = await Hive
      .openBox<Book>(Storage._bookHistory);

    selectedTagsBox = await Hive
      .openBox<TagWithState>(Storage._selectedTags);

    _boolBox = await Hive
      .openBox<bool>(Storage._bools);
    _doubleBox = await Hive
      .openBox<double>(Storage._doubles);
    _intBox = await Hive
      .openBox<int>(Storage._integers);
    _stringBox = await Hive
      .openBox<String>(Storage._strings);

    if(!preferences.resetHistoryOnBoot) {
      // Compact history.
      final compactedHistory = Map<int, Book>
        .fromEntries(storage.booksHistoryBox.values.toList().reversed
          .map((book) => MapEntry(book.id, book)),
        ).values.toList().reversed;
      
      await booksHistoryBox.clear();
      booksHistoryBox.addAll(compactedHistory);
    } else 
      await booksHistoryBox.clear();

    if(selectedTagsBox.isEmpty)
      await updateTags();
  }

  Future<void> updateTags() async {
    final request = await HttpClient()
      .getUrl(Uri
        .parse('https://github.com/LacticWhale/tags/raw/master/tags'),
      );
    final response = await request.close();
    final bytes = (await response.toList()).expand((e) => e).toList();

    final data = gzip.decode(bytes);
    
    await selectedTagsBox.clear();

    selectedTagsBox.addAll(binary.deserialize<List<Tag>>(data).map(TagWithState.unnamed));
  }

  @override
  Future<void> remove(String key) => Future.wait([
    _boolBox.delete(key),
    _doubleBox.delete(key),
    _intBox.delete(key),
    _stringBox.delete(key),
  ]);

  @override
  Future<void> removeAll() async {
    final keys = getKeys();

    await Future.wait([
      _boolBox.deleteAll(keys),
      _doubleBox.deleteAll(keys),
      _intBox.deleteAll(keys),
      _stringBox.deleteAll(keys),
    ]);
  }

  @override
  Future<void> setBool(String key, bool? value) =>
    value != null ? _boolBox.put(key, value) : Future.value();

  @override
  Future<void> setDouble(String key, double? value) =>
    value != null ? _doubleBox.put(key, value) : Future.value();


  @override
  Future<void> setInt(String key, int? value) =>
    value != null ? _intBox.put(key, value) : Future.value();
  
  @override
  Future<void> setString(String key, String? value) =>
    value != null ? _stringBox.put(key, value) : Future.value();  

  @override
  Future<void> setObject<T>(String key, T? value) {
    if(value == null)
      return Future.value();

    if(T == bool)
      return setBool(key, value as bool);
    else if(T == double)
      return setDouble(key, value as double);
    else if(T == int)
      return setInt(key, value as int);
    else if(T == String)
      return setString(key, value as String);
    else 
      throw Exception('Unsupported type.');
  }
}
