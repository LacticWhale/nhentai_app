extension StringAddQuery on String {
  String addQuery(Map<String, dynamic> map) => '$this?${Uri(queryParameters: map).query}';
}
