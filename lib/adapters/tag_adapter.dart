// ignore: import_of_legacy_library_into_null_safe
import 'package:binary/binary.dart';
import 'package:nhentai/data_model.dart';

class TagAdapter extends AdapterFor<Tag> {
  @override
  Tag read(BinaryReader reader) => Tag(
    id: reader.readInt32(), 
    type: TagType.getByName(reader.read()), 
    name: reader.read(), 
    url: Uri.parse(reader.read()),
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
