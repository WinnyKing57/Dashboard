// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rss_feed_source.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RssFeedSourceAdapter extends TypeAdapter<RssFeedSource> {
  @override
  final int typeId = 3;

  @override
  RssFeedSource read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RssFeedSource(
      id: fields[0] as String,
      url: fields[1] as String,
      name: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RssFeedSource obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RssFeedSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
