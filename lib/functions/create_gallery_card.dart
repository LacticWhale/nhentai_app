import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhentai/data_model.dart';

import '../api.dart';
import '../app.dart';
import '../main.dart';
import 'image_builder.dart';

Widget createGalleryCard(BuildContext context, Book book) => createGalleryCardWithCallback(null)(context, book);

Widget Function(BuildContext context, Book book) createGalleryCardWithCallback(FutureOr<dynamic> Function()? cb) => (context, book) => GestureDetector(
  onTap: () async {
    if(preferences.recordHistory)
      storage.booksHistoryBox.add(book);

    GoRouter.of(context).push('/book/${book.id}', extra: book)
      .then((value) {
        cb?.call();
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
            fit: BoxFit.cover,
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
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).cardColor.withAlpha(127),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.library_books, size: (Theme.of(context).iconTheme.size ?? 24) / 2,),
                    Text(book.pages.length.toString(), 
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
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
