import 'package:hive_flutter/hive_flutter.dart';
import 'package:quest_app_new/data/progress_model.dart';
import 'package:quest_app_new/data/models.dart';

class ProgressRepository {
  static const _progressBoxName = 'progressBox';
  static const _progressKey = 'userProgress';

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(QuestProgressAdapter().typeId)) {
      Hive.registerAdapter(QuestProgressAdapter());
    }
    await Hive.openBox<QuestProgress>(_progressBoxName);
  }

  Box<QuestProgress> get _progressBox => Hive.box<QuestProgress>(_progressBoxName);

  QuestProgress _getOrCreateProgress() {
    return _progressBox.get(_progressKey) ?? QuestProgress();
  }

  Future<void> _saveProgress(QuestProgress progress) async {
    await _progressBox.put(_progressKey, progress);
  }

  Future<void> saveCurrentQuestState(String questId, int step, int dialogueIndex) async {
    final progress = _getOrCreateProgress();
    progress.currentQuestId = questId;
    progress.currentStep = step;
    progress.currentDialogueIndex = dialogueIndex;
    await _saveProgress(progress);
  }

  QuestProgress? loadCurrentQuestState() {
    final progress = _progressBox.get(_progressKey);
    if (progress != null && progress.currentQuestId != null) {
      return progress;
    }
    return null;
  }

  Future<void> clearCurrentQuestState() async {
    final progress = _getOrCreateProgress();
    progress.currentQuestId = null;
    progress.currentStep = null;
    progress.currentDialogueIndex = null;
    await _saveProgress(progress);
  }

  Future<void> addCompletedQuest(String questId, List<DialogueLine> dialogues) async {
    final progress = _getOrCreateProgress();
    if (!progress.completedQuests.contains(questId)) {
      progress.completedQuests.add(questId);
      // Конвертируем диалоги в JSON и сохраняем
      progress.dialogueHistory[questId] = dialogues.map((d) => d.toJson()).toList();
    }
    await _saveProgress(progress);
  }

  Future<void> saveAvatar(String avatarPath) async {
    final progress = _getOrCreateProgress();
    progress.avatarPath = avatarPath;
    await _saveProgress(progress);
  }

  QuestProgress? loadUserProfile() {
    return _progressBox.get(_progressKey);
  }
  Future<void> resetProgress() async {
    final progress = QuestProgress(); // Создаем пустой объект прогресса
    await _saveProgress(progress);
  }
}