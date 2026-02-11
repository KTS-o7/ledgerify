// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WidgetConfigAdapter extends TypeAdapter<WidgetConfig> {
  @override
  final int typeId = 17;

  @override
  WidgetConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WidgetConfig(
      quickAddCategories: (fields[0] as List?)?.cast<int>(),
      showBudgetProgress: fields[1] as bool,
      showAlerts: fields[2] as bool,
      lastSynced: fields[3] as DateTime?,
      updateFrequencyMinutes: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WidgetConfig obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.quickAddCategories)
      ..writeByte(1)
      ..write(obj.showBudgetProgress)
      ..writeByte(2)
      ..write(obj.showAlerts)
      ..writeByte(3)
      ..write(obj.lastSynced)
      ..writeByte(4)
      ..write(obj.updateFrequencyMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
