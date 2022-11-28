import 'package:hive/hive.dart';
import 'package:nhentai/data_model.dart';

class HiveImageAdapter extends TypeAdapter<Image> {
  @override
  int get typeId => 4;

  @override
  Image read(BinaryReader reader) => Image(
    id: reader.readUint32(), 
    media: reader.readUint32(), 
    isThumbnail: reader.readBool(), 
    type: reader.read() as ImageType,
    width: reader.readBool() ? reader.readUint32() : null,
    height: reader.readBool() ? reader.readUint32() : null,
  );

  @override
  void write(BinaryWriter writer, Image obj) {
    writer
      ..writeUint32(obj.id)
      ..writeUint32(obj.media)
      ..writeBool(obj.isThumbnail)
      ..write(obj.type);

    if(obj.width == null)
      writer.writeBool(false);
    else 
      writer
        ..writeBool(true)
        ..writeUint32(obj.width!);

    if(obj.height == null)
      writer.writeBool(false);
    else 
      writer
        ..writeBool(true)
        ..writeUint32(obj.height!);
  }

}
