// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_station.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FavoriteStationAdapter extends TypeAdapter<FavoriteStation> {
  @override
  final int typeId = 6;

  @override
  FavoriteStation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavoriteStation(
      stationuuid: fields[0] as String,
      name: fields[1] as String,
      urlResolved: fields[2] as String,
      country: fields[3] as String?,
      favicon: fields[4] as String?,
      tags: (fields[5] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteStation obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.stationuuid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.urlResolved)
      ..writeByte(3)
      ..write(obj.country)
      ..writeByte(4)
      ..write(obj.favicon)
      ..writeByte(5)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteStationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
