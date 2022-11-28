
import 'dart:convert';

import 'package:nhentai/data_model.dart';

extension ImageToJson on Image {
  String toJson() => jsonEncode({
    't': type.name,
    'w': width,
    'h': height,
  });
}
