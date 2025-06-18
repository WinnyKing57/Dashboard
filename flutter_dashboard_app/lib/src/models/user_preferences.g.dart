// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 0;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      themeModeName: fields[0] as String,
      rssNotificationsEnabled: fields[1] as bool,
      rssRefreshFrequencyHours: fields[2] as int,
      colorSeedValue: fields[3] as int?, // Add this line
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(4) // Incremented number of fields
      ..writeByte(0)
      ..write(obj.themeModeName)
      ..writeByte(1)
      ..write(obj.rssNotificationsEnabled)
      ..writeByte(2)
      ..write(obj.rssRefreshFrequencyHours)
      ..writeByte(3) // Add this line for the new field index
      ..write(obj.colorSeedValue); // Add this line to write the new field's value
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
