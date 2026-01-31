// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringExpenseAdapter extends TypeAdapter<RecurringExpense> {
  @override
  final int typeId = 4;

  @override
  RecurringExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringExpense(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as ExpenseCategory,
      frequency: fields[4] as RecurrenceFrequency,
      customIntervalDays: fields[5] as int,
      weekdays: (fields[6] as List?)?.cast<int>(),
      dayOfMonth: fields[7] as int?,
      startDate: fields[8] as DateTime,
      endDate: fields[9] as DateTime?,
      lastGeneratedDate: fields[10] as DateTime?,
      nextDueDate: fields[11] as DateTime,
      isActive: fields[12] as bool,
      note: fields[13] as String?,
      createdAt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringExpense obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.customIntervalDays)
      ..writeByte(6)
      ..write(obj.weekdays)
      ..writeByte(7)
      ..write(obj.dayOfMonth)
      ..writeByte(8)
      ..write(obj.startDate)
      ..writeByte(9)
      ..write(obj.endDate)
      ..writeByte(10)
      ..write(obj.lastGeneratedDate)
      ..writeByte(11)
      ..write(obj.nextDueDate)
      ..writeByte(12)
      ..write(obj.isActive)
      ..writeByte(13)
      ..write(obj.note)
      ..writeByte(14)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceFrequencyAdapter extends TypeAdapter<RecurrenceFrequency> {
  @override
  final int typeId = 3;

  @override
  RecurrenceFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceFrequency.daily;
      case 1:
        return RecurrenceFrequency.weekly;
      case 2:
        return RecurrenceFrequency.monthly;
      case 3:
        return RecurrenceFrequency.yearly;
      case 4:
        return RecurrenceFrequency.custom;
      default:
        return RecurrenceFrequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceFrequency obj) {
    switch (obj) {
      case RecurrenceFrequency.daily:
        writer.writeByte(0);
        break;
      case RecurrenceFrequency.weekly:
        writer.writeByte(1);
        break;
      case RecurrenceFrequency.monthly:
        writer.writeByte(2);
        break;
      case RecurrenceFrequency.yearly:
        writer.writeByte(3);
        break;
      case RecurrenceFrequency.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
