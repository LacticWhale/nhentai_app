import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/data_model.dart';

import '../api.dart';
import '../main.dart';
import '../screen/pages/book.dart';
import 'image_builder.dart';

Widget createGalleryCard(BuildContext context, Book book) => createGalleryCardWithCallback(null)(context, book);

Widget Function(BuildContext context, Book book) createGalleryCardWithCallback(FutureOr<dynamic> Function()? cb) => (context, book) => GestureDetector(
  onTap: () async {
    if(preferences.recordHistory)
      storage.booksHistoryBox.add(book);
    Navigator.of(context).push(
      MaterialPageRoute<BookPage>(
        builder: (context) =>
            BookPage(book: book),
      ),
    ).then((value) { 
      if(cb != null)
        cb();
    });
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
            imageUrl: book
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
                book.title.pretty,
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
