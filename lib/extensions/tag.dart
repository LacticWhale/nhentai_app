import 'dart:convert';

import 'package:nhentai/data_model.dart';

extension TagToJson on Tag {
  String toJson() => jsonEncode({
    'id': id,
    'type': type.name,
    'name': name,
    'url': url.toString(),
    'count': count,
  });
}
