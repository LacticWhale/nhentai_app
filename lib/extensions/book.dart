import 'dart:convert';

import 'package:nhentai/data_model.dart';

extension BookToJson on Book {
  String toJson() => jsonEncode({
    'id': id,
    'media_id': media,
    'title': {
      'english': title.english,
      'japanese': title.japanese,
      'pretty': title.pretty,
    },
    'images': {
      'pages': pages.map((e) => {
        't': e.type == ImageType.gif ? 'g' : e.type == ImageType.jpeg ? 'j' : 'p',
        'w': e.width,
        'h': e.height,
      },).toList(),
      'cover': {
        't': cover.type == ImageType.gif ? 'g' : cover.type == ImageType.jpeg ? 'j' : 'p',
        'w': cover.width,
        'h': cover.height,
      },
      'thumbnail': {
        't': thumbnail.type == ImageType.gif ? 'g' : thumbnail.type == ImageType.jpeg ? 'j' : 'p',
        'w': thumbnail.width,
        'h': thumbnail.height,
      },
    },    
    'scanlator': scanlator ?? '',
    'upload_date': uploaded.millisecondsSinceEpoch,
    'tags': tags.map((e) => {
      'id': e.id,
      'type': e.type.name,
      'name': e.name,
      'url': e.url.toString(),
      'count': e.count,
    },).toList(),
    'num_pages': pages.length,
    'num_favorites': favorites,
  });
}
