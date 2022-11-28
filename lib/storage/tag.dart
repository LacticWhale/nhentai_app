import 'package:hive/hive.dart';
import 'package:nhentai/data_model.dart';

class HiveTagAdapter extends TypeAdapter<Tag> {
  @override
  int get typeId => 6;

  @override
  Tag read(BinaryReader reader) => Tag(
    id: reader.readInt32(), 
    type: TagType.getByName(reader.read() as String), 
    name: reader.read() as String, 
    url: Uri.parse(reader.read() as String),
    count: reader.readInt32(), 
  );

  @override
  void write(BinaryWriter writer, Tag obj) {
    writer
      ..writeInt32(obj.id)
      ..write(obj.type.name)
      ..write(obj.name)
      ..write(obj.url.path)
      ..writeInt32(obj.count);
  }
  
}
