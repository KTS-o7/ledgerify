// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalAllocationAdapter extends TypeAdapter<GoalAllocation> {
  @override
  final int typeId = 10;

  @override
  GoalAllocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalAllocation(
      goalId: fields[0] as String,
      percentage: fields[1] as double,
      amount: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, GoalAllocation obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.goalId)
      ..writeByte(1)
      ..write(obj.percentage)
      ..writeByte(2)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalAllocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IncomeAdapter extends TypeAdapter<Income> {
  @override
  final int typeId = 11;

  @override
  Income read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Income(
      id: fields[0] as String,
      amount: fields[1] as double,
      source: fields[2] as IncomeSource,
      description: fields[3] as String?,
      date: fields[4] as DateTime,
      createdAt: fields[5] as DateTime?,
      goalAllocations: (fields[6] as List?)?.cast<GoalAllocation>(),
      recurringIncomeId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Income obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.source)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.goalAllocations)
      ..writeByte(7)
      ..write(obj.recurringIncomeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IncomeSourceAdapter extends TypeAdapter<IncomeSource> {
  @override
  final int typeId = 9;

  @override
  IncomeSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return IncomeSource.salary;
      case 1:
        return IncomeSource.freelance;
      case 2:
        return IncomeSource.business;
      case 3:
        return IncomeSource.investment;
      case 4:
        return IncomeSource.gift;
      case 5:
        return IncomeSource.refund;
      case 6:
        return IncomeSource.other;
      default:
        return IncomeSource.salary;
    }
  }

  @override
  void write(BinaryWriter writer, IncomeSource obj) {
    switch (obj) {
      case IncomeSource.salary:
        writer.writeByte(0);
        break;
      case IncomeSource.freelance:
        writer.writeByte(1);
        break;
      case IncomeSource.business:
        writer.writeByte(2);
        break;
      case IncomeSource.investment:
        writer.writeByte(3);
        break;
      case IncomeSource.gift:
        writer.writeByte(4);
        break;
      case IncomeSource.refund:
        writer.writeByte(5);
        break;
      case IncomeSource.other:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
