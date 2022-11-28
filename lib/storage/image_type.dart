import 'package:hive/hive.dart';
import 'package:nhentai/data_model.dart';

class HiveImageTypeAdapter extends TypeAdapter<ImageType> {
  @override
  int get typeId => 5;

  @override
  ImageType read(BinaryReader reader) => ImageType.getByType(reader.readString());

  @override
  void write(BinaryWriter writer, ImageType obj) {
    writer.writeString(obj.extension);
  }

}
