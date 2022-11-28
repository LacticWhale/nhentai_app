import 'dart:convert';

import 'package:nhentai/data_model.dart';

extension BookTitleToJson on BookTitle {
  String toJson() => jsonEncode({
    'english': english,
    'japanese': japanese,
    'pretty': pretty,
  });
}
