
import 'package:flutter/material.dart';
import 'package:nhentai/data_model.dart';
import 'package:nhentai/nhentai.dart';

import '../../functions/create_gallery_card.dart';
import '../../main.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _HistoryPageState();

}

class _HistoryPageState extends State<HistoryPage> {
  Iterable<Book> get _books => Map<int, Book>.fromEntries(storage.booksHistoryBox.values.toList().reversed.map((book) => MapEntry(book.id, book))).values.toList();

  @override
  Widget build(BuildContext context) => Material(
    child: SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await storage.booksHistoryBox.clear();

                setState(() { });
              },
            ),
          ],
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
