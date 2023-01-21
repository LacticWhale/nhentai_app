import 'package:hive_flutter/adapters.dart';
import 'package:nhentai/data_model.dart';
class HiveBookAdapter extends TypeAdapter<Book> {
  @override
  int get typeId => 1;

  @override
  Book read(BinaryReader reader) => Book.parseJson(reader.readString());

  @override
  void write(BinaryWriter writer, Book obj) {
    writer.writeString(obj.toJson());
  }

}
