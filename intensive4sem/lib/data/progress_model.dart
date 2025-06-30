import 'package:hive/hive.dart';

// Указываем, что для этого файла будет сгенерирована часть
part 'progress_model.g.dart';

// Аннотация для Hive. typeId должен быть уникальным для каждой модели в проекте.
@HiveType(typeId: 0)
class QuestProgress extends HiveObject {
  // Поля, которые мы хотим сохранить в базе данных.
  // У каждого поля должен быть уникальный (в рамках класса) индекс.
  @HiveField(0)
  late String questId;

  @HiveField(1)
  late int currentStep;

  @HiveField(2)
  late int currentDialogueIndex;
}