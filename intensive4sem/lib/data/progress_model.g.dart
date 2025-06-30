// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestProgressAdapter extends TypeAdapter<QuestProgress> {
  @override
  final int typeId = 0;

  @override
  QuestProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestProgress()
      ..questId = fields[0] as String
      ..currentStep = fields[1] as int
      ..currentDialogueIndex = fields[2] as int;
  }

  @override
  void write(BinaryWriter writer, QuestProgress obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.questId)
      ..writeByte(1)
      ..write(obj.currentStep)
      ..writeByte(2)
      ..write(obj.currentDialogueIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
