// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rss_feed_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RssFeedItemAdapter extends TypeAdapter<RssFeedItem> {
  @override
  final int typeId = 4;

  @override
  RssFeedItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RssFeedItem(
      guid: fields[0] as String?,
      title: fields[1] as String?,
      link: fields[2] as String?,
      description: fields[3] as String?,
      pubDate: fields[4] as String?,
      feedSourceId: fields[5] as String,
    )..itemUniqueKey = fields[6] as String?;
  }

  @override
  void write(BinaryWriter writer, RssFeedItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.guid)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.link)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.pubDate)
      ..writeByte(5)
      ..write(obj.feedSourceId)
      ..writeByte(6)
      ..write(obj.itemUniqueKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RssFeedItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
