// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecentItemAdapter extends TypeAdapter<RecentItem> {
  @override
  final int typeId = 1;

  @override
  RecentItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecentItem(
      code: fields[0] as String,
      name: fields[1] as String,
      dateVisited: fields[2] as DateTime,
      isFav: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RecentItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dateVisited)
      ..writeByte(3)
      ..write(obj.isFav);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
