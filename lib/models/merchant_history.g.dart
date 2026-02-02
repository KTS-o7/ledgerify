// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MerchantHistoryAdapter extends TypeAdapter<MerchantHistory> {
  @override
  final int typeId = 14;

  @override
  MerchantHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MerchantHistory(
      name: fields[0] as String,
      usageCount: fields[1] as int,
      lastUsed: fields[2] as DateTime?,
      categoryUsage: (fields[3] as Map?)?.cast<String, int>(),
      defaultCategoryName: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MerchantHistory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.usageCount)
      ..writeByte(2)
      ..write(obj.lastUsed)
      ..writeByte(3)
      ..write(obj.categoryUsage)
      ..writeByte(4)
      ..write(obj.defaultCategoryName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MerchantHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
