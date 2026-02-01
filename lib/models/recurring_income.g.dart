// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_income.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringIncomeAdapter extends TypeAdapter<RecurringIncome> {
  @override
  final int typeId = 12;

  @override
  RecurringIncome read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringIncome(
      id: fields[0] as String,
      amount: fields[1] as double,
      source: fields[2] as IncomeSource,
      description: fields[3] as String?,
      frequency: fields[4] as RecurrenceFrequency,
      nextDate: fields[5] as DateTime,
      isActive: fields[6] as bool,
      goalAllocations: (fields[7] as List?)?.cast<GoalAllocation>(),
      createdAt: fields[8] as DateTime?,
      lastGeneratedDate: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringIncome obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.source)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.nextDate)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.goalAllocations)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.lastGeneratedDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringIncomeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
