import 'package:hive/hive.dart';
import 'package:nhentai/data_model.dart';

import '../widgets/tag_block.dart';

class HiveTagWithStateAdapter extends TypeAdapter<TagWithState> {
  @override
  int get typeId => 2;

  @override
  TagWithState read(BinaryReader reader) => TagWithState(
    tag: Tag(
      id: reader.readInt32(), 
      type: TagType.getByName(reader.read() as String), 
      name: reader.read() as String, 
      url: Uri.parse(reader.read() as String),
      count: reader.readInt32(), 
    ),
    state: reader.readBool() 
      ? TagState.values.elementAt(reader.readUint32()) 
      : TagState.none,
  );

  @override
  void write(BinaryWriter writer, Tag obj) {
    writer
      ..writeInt32(obj.id)
      ..write(obj.type.name)
      ..write(obj.name)
      ..write(obj.url.path)
      ..writeInt32(obj.count)
      ..writeBool(obj is TagWithState);
    if(obj is TagWithState)
      writer.writeUint32(obj.state.index);
  }
  
}
