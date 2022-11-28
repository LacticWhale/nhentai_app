
import 'package:flutter/material.dart';
import 'package:nhentai/data_model.dart';
import 'package:nhentai/nhentai.dart';

import '../../functions/create_gallery_card.dart';
import '../../main.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _FavoritesPageState();

}

class _FavoritesPageState extends State<FavoritesPage> { 
  final _favoriteBooksBox = storage.favoriteBooksBox;
  Iterable<Book> get _books => _favoriteBooksBox.values;

  @override
  Widget build(BuildContext context) => Material(
    child: SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
        ),
        body: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 9/13,
          ), 
          itemBuilder: (context, index) => createGalleryCard(context, _books.elementAt(index)),
          itemCount: _books.length,
        ),
      ),
    ),
  );

}
