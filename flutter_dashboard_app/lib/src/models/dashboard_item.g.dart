// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DashboardItemAdapter extends TypeAdapter<DashboardItem> {
  @override
  final int typeId = 2;

  @override
  DashboardItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DashboardItem(
      id: fields[0] as String,
      widgetType: fields[1] as String,
      order: fields[2] as int,
      widgetData: fields[3] as dynamic,
    );
  }

  @override
  void write(BinaryWriter writer, DashboardItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.widgetType)
      ..writeByte(2)
      ..write(obj.order)
      ..writeByte(3)
      ..write(obj.widgetData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
