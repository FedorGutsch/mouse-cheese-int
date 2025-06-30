import 'package:hive_flutter/hive_flutter.dart';
import 'package:quest_app/data/progress_model.dart';

class ProgressRepository {
  // Имя "коробки" (таблицы) в Hive
  static const _progressBoxName = 'progressBox';
  // Ключ, по которому будет храниться единственный объект с прогрессом
  static const _currentProgressKey = 'currentProgress';

  // Метод для инициализации. Открывает "коробку" для хранения данных.
  Future<void> init() async {
    // Регистрируем адаптер перед открытием коробки, если это не сделано в main
    if (!Hive.isAdapterRegistered(QuestProgressAdapter().typeId)) {
      Hive.registerAdapter(QuestProgressAdapter());
    }
    await Hive.openBox<QuestProgress>(_progressBoxName);
  }

  // Приватный геттер для удобного доступа к открытой коробке
  Box<QuestProgress> get _progressBox => Hive.box<QuestProgress>(_progressBoxName);

  // Сохраняем текущий прогресс
  Future<void> saveProgress(QuestProgress progress) async {
    await _progressBox.put(_currentProgressKey, progress);
  }

  // Загружаем прогресс. Может вернуть null, если ничего не сохранено.
  QuestProgress? loadProgress() {
    return _progressBox.get(_currentProgressKey);
  }

  // Очищаем прогресс (например, после завершения квеста)
  Future<void> clearProgress() async {
    await _progressBox.delete(_currentProgressKey);
  }
}