import 'package:hive_flutter/adapters.dart';
import 'package:nhentai/data_model.dart';

import '../widgets/tag_block.dart';

class HiveTagWithStateAdapter extends TypeAdapter<TagWithState> {
  @override
  int get typeId => 3;

  @override
  TagWithState read(BinaryReader reader) => TagWithState(
    tag: Tag(
      id: reader.readInt32(), 
      type: TagType.getByName(reader.read() as String), 
      name: reader.read() as String, 
      url: reader.read() as String,
      count: reader.readInt32(), 
    ),
    state: TagState.values.elementAt(reader.readUint32()),
  );

  @override
  void write(BinaryWriter writer, TagWithState obj) {
    writer
      ..writeInt32(obj.id)
      ..write(obj.type.name)
      ..write(obj.name)
      ..write(obj.url)
      ..writeInt32(obj.count)
      ..writeUint32(obj.state.index);
  }
  
}
