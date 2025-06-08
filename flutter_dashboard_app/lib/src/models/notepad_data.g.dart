// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notepad_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotepadDataAdapter extends TypeAdapter<NotepadData> {
  @override
  final int typeId = 1;

  @override
  NotepadData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotepadData(
      content: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NotepadData obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.content);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotepadDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
