// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationPreferencesAdapter
    extends TypeAdapter<NotificationPreferences> {
  @override
  final int typeId = 13;

  @override
  NotificationPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationPreferences(
      masterEnabled: fields[0] as bool,
      budgetAlertsEnabled: fields[1] as bool,
      budgetWarningThreshold: fields[2] as int,
      customBudgetThresholds: (fields[3] as List?)?.cast<int>(),
      recurringRemindersEnabled: fields[4] as bool,
      recurringReminderDaysBefore: fields[5] as int,
      overdueRemindersEnabled: fields[6] as bool,
      goalNotificationsEnabled: fields[7] as bool,
      goalMilestones: (fields[8] as List?)?.cast<int>(),
      weeklySummaryEnabled: fields[9] as bool,
      weeklySummaryDay: fields[10] as int,
      weeklySummaryHour: fields[11] as int,
      weeklySummaryMinute: fields[12] as int,
      dailyReminderEnabled: fields[13] as bool,
      dailyReminderHour: fields[14] as int,
      dailyReminderMinute: fields[15] as int,
      quietHoursEnabled: fields[16] as bool,
      quietHoursStartHour: fields[17] as int,
      quietHoursStartMinute: fields[18] as int,
      quietHoursEndHour: fields[19] as int,
      quietHoursEndMinute: fields[20] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationPreferences obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.masterEnabled)
      ..writeByte(1)
      ..write(obj.budgetAlertsEnabled)
      ..writeByte(2)
      ..write(obj.budgetWarningThreshold)
      ..writeByte(3)
      ..write(obj.customBudgetThresholds)
      ..writeByte(4)
      ..write(obj.recurringRemindersEnabled)
      ..writeByte(5)
      ..write(obj.recurringReminderDaysBefore)
      ..writeByte(6)
      ..write(obj.overdueRemindersEnabled)
      ..writeByte(7)
      ..write(obj.goalNotificationsEnabled)
      ..writeByte(8)
      ..write(obj.goalMilestones)
      ..writeByte(9)
      ..write(obj.weeklySummaryEnabled)
      ..writeByte(10)
      ..write(obj.weeklySummaryDay)
      ..writeByte(11)
      ..write(obj.weeklySummaryHour)
      ..writeByte(12)
      ..write(obj.weeklySummaryMinute)
      ..writeByte(13)
      ..write(obj.dailyReminderEnabled)
      ..writeByte(14)
      ..write(obj.dailyReminderHour)
      ..writeByte(15)
      ..write(obj.dailyReminderMinute)
      ..writeByte(16)
      ..write(obj.quietHoursEnabled)
      ..writeByte(17)
      ..write(obj.quietHoursStartHour)
      ..writeByte(18)
      ..write(obj.quietHoursStartMinute)
      ..writeByte(19)
      ..write(obj.quietHoursEndHour)
      ..writeByte(20)
      ..write(obj.quietHoursEndMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
