// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sound_button.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SoundButtonAdapter extends TypeAdapter<SoundButton> {
  @override
  final int typeId = 0;

  @override
  SoundButton read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SoundButton(
      id: fields[0] as String,
      label: fields[1] as String,
      audioFilePath: fields[2] as String,
      color: fields[3] as int,
      createdAt: fields[4] as DateTime,
      categoryId: fields[5] as String?,
      isFavorite: fields[6] as bool,
      order: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SoundButton obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.audioFilePath)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundButtonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
