import 'package:hive/hive.dart';
import 'package:nhentai/data_model.dart';

class HiveBookAdapter extends TypeAdapter<Book> {
  @override
  int get typeId => 1;

  @override
  Book read(BinaryReader reader) => Book(
    title: reader.read() as BookTitle, 
    id: reader.readInt32(), 
    media: reader.readInt32(), 
    favorites: reader.readInt32(), 
    scanlator: reader.readString(), 
    uploaded: reader.read() as DateTime, 
    tags: TagsList(reader.readList().map((e) => e as Tag)), 
    cover: reader.read() as Image, 
    thumbnail: reader.read() as Image, 
    pages: reader.readList().map((e) => e as Image),
  );

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..write(obj.title)
      ..writeUint32(obj.id)
      ..writeUint32(obj.media)
      ..writeUint32(obj.favorites)
      ..writeString(obj.scanlator ?? '')
      ..write(obj.uploaded)
      ..writeList(obj.tags)
      ..write(obj.cover)
      ..write(obj.thumbnail)
      ..writeList(obj.pages.toList());
  }

}
