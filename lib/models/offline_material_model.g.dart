// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_material_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineMaterialAdapter extends TypeAdapter<OfflineMaterial> {
  @override
  final int typeId = 0;

  @override
  OfflineMaterial read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineMaterial(
      id: fields[0] as String,
      title: fields[1] as String,
      originalUrl: fields[2] as String,
      localFilePath: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineMaterial obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.originalUrl)
      ..writeByte(3)
      ..write(obj.localFilePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineMaterialAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
