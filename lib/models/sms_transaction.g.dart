// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmsTransactionAdapter extends TypeAdapter<SmsTransaction> {
  @override
  final int typeId = 15;

  @override
  SmsTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmsTransaction(
      smsId: fields[0] as String,
      rawMessage: fields[1] as String,
      senderId: fields[2] as String,
      smsDate: fields[3] as DateTime,
      amount: fields[4] as double,
      transactionType: fields[5] as String,
      merchant: fields[6] as String?,
      accountNumber: fields[7] as String?,
      status: fields[8] as SmsTransactionStatus,
      linkedExpenseId: fields[9] as String?,
      linkedIncomeId: fields[10] as String?,
      createdAt: fields[11] as DateTime?,
      confidence: fields[12] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SmsTransaction obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.smsId)
      ..writeByte(1)
      ..write(obj.rawMessage)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.smsDate)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.transactionType)
      ..writeByte(6)
      ..write(obj.merchant)
      ..writeByte(7)
      ..write(obj.accountNumber)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.linkedExpenseId)
      ..writeByte(10)
      ..write(obj.linkedIncomeId)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.confidence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SmsTransactionStatusAdapter extends TypeAdapter<SmsTransactionStatus> {
  @override
  final int typeId = 16;

  @override
  SmsTransactionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SmsTransactionStatus.pending;
      case 1:
        return SmsTransactionStatus.confirmed;
      case 2:
        return SmsTransactionStatus.skipped;
      case 3:
        return SmsTransactionStatus.deleted;
      default:
        return SmsTransactionStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SmsTransactionStatus obj) {
    switch (obj) {
      case SmsTransactionStatus.pending:
        writer.writeByte(0);
        break;
      case SmsTransactionStatus.confirmed:
        writer.writeByte(1);
        break;
      case SmsTransactionStatus.skipped:
        writer.writeByte(2);
        break;
      case SmsTransactionStatus.deleted:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsTransactionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
