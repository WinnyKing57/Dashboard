// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rss_widget_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RssWidgetConfigAdapter extends TypeAdapter<RssWidgetConfig> {
  @override
  final int typeId = 5;

  @override
  RssWidgetConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RssWidgetConfig(
      feedSourceId: fields[0] as String,
      feedSourceName: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RssWidgetConfig obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.feedSourceId)
      ..writeByte(1)
      ..write(obj.feedSourceName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RssWidgetConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
