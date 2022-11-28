import 'package:hive/hive.dart';
import 'package:nhentai/data_model.dart';

class HiveBookTitleAdapter extends TypeAdapter<BookTitle> {
  @override
  int get typeId => 3;

  @override
  BookTitle read(BinaryReader reader) => BookTitle(
    english: reader.readBool() ? reader.readString() : null, 
    japanese: reader.readBool() ? reader.readString() : null, 
    pretty: reader.readString(),
  );

  @override
  void write(BinaryWriter writer, BookTitle obj) {
    if(obj.english == null)
      writer.writeBool(false);
    else 
      writer
        ..writeBool(true)
        ..writeString(obj.english!);
    
    if(obj.japanese == null)
      writer.writeBool(false);
    else 
      writer
        ..writeBool(true)
        ..writeString(obj.japanese!);

    writer.writeString(obj.pretty);
  }

}
