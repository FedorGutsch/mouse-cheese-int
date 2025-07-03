// lib/data/progress_model.dart

import 'package:hive/hive.dart';
part 'progress_model.g.dart';

@HiveType(typeId: 0)
class QuestProgress extends HiveObject {
  @HiveField(0)
  String? currentQuestId;

  @HiveField(1)
  int? currentStep;

  @HiveField(2)
  int? currentDialogueIndex;

  @HiveField(3)
  String? avatarPath;

  @HiveField(4)
  List<String> completedQuests = [];

  // --- НОВОЕ ПОЛЕ ДЛЯ ИСТОРИИ ДИАЛОГОВ ---
  // Ключ - questId, значение - список диалогов в формате JSON
  @HiveField(5)
  Map<String, List<Map<String, dynamic>>> dialogueHistory = {};
}