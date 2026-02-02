// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      amount: fields[1] as double,
      category: fields[2] as ExpenseCategory,
      date: fields[3] as DateTime,
      note: fields[4] as String?,
      source: fields[5] as ExpenseSource,
      merchant: fields[6] as String?,
      createdAt: fields[7] as DateTime?,
      customCategoryId: fields[8] as String?,
      tagIds: (fields[9] as List?)?.cast<String>(),
      recurringExpenseId: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.source)
      ..writeByte(6)
      ..write(obj.merchant)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.customCategoryId)
      ..writeByte(9)
      ..write(obj.tagIds)
      ..writeByte(10)
      ..write(obj.recurringExpenseId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExpenseSourceAdapter extends TypeAdapter<ExpenseSource> {
  @override
  final int typeId = 1;

  @override
  ExpenseSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExpenseSource.manual;
      case 1:
        return ExpenseSource.sms;
      case 2:
        return ExpenseSource.recurring;
      default:
        return ExpenseSource.manual;
    }
  }

  @override
  void write(BinaryWriter writer, ExpenseSource obj) {
    switch (obj) {
      case ExpenseSource.manual:
        writer.writeByte(0);
        break;
      case ExpenseSource.sms:
        writer.writeByte(1);
        break;
      case ExpenseSource.recurring:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExpenseCategoryAdapter extends TypeAdapter<ExpenseCategory> {
  @override
  final int typeId = 2;

  @override
  ExpenseCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExpenseCategory.food;
      case 1:
        return ExpenseCategory.transport;
      case 2:
        return ExpenseCategory.shopping;
      case 3:
        return ExpenseCategory.entertainment;
      case 4:
        return ExpenseCategory.bills;
      case 5:
        return ExpenseCategory.health;
      case 6:
        return ExpenseCategory.education;
      case 7:
        return ExpenseCategory.other;
      default:
        return ExpenseCategory.food;
    }
  }

  @override
  void write(BinaryWriter writer, ExpenseCategory obj) {
    switch (obj) {
      case ExpenseCategory.food:
        writer.writeByte(0);
        break;
      case ExpenseCategory.transport:
        writer.writeByte(1);
        break;
      case ExpenseCategory.shopping:
        writer.writeByte(2);
        break;
      case ExpenseCategory.entertainment:
        writer.writeByte(3);
        break;
      case ExpenseCategory.bills:
        writer.writeByte(4);
        break;
      case ExpenseCategory.health:
        writer.writeByte(5);
        break;
      case ExpenseCategory.education:
        writer.writeByte(6);
        break;
      case ExpenseCategory.other:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
