import 'package:hive/hive.dart';
import 'package:nhentai/data_model.dart';
import 'package:nhentai/data_model_prefixed.dart';

class HiveBookAdapter extends TypeAdapter<Book> {
  @override
  int get typeId => 1;

  @override
  Book read(BinaryReader reader) => NHentaiMapper.fromJson(reader.readString());

  @override
  void write(BinaryWriter writer, Book obj) {
    writer.writeString(obj.toJson());
  }

}
