import 'package:equatable/equatable.dart';
import 'package:quest_app/data/models.dart';

// Абстрактный базовый класс для всех состояний.
abstract class QuestState extends Equatable {
  const QuestState();

  @override
  List<Object?> get props => [];
}

/// Начальное, пустое состояние.
class QuestInitial extends QuestState {}

/// Состояние, когда квест находится в процессе загрузки.
/// UI может показать индикатор загрузки.
class QuestLoadInProgress extends QuestState {}

/// Состояние, когда квест успешно загружен и игра активна.
/// Содержит все необходимые данные для отображения текущего шага.
class QuestLoadSuccess extends QuestState {
  final Quest quest;
  final int currentStep;
  final int currentDialogueIndex;
  final bool isDialogueFinished;

  const QuestLoadSuccess({
    required this.quest,
    this.currentStep = 0,
    this.currentDialogueIndex = 0,
    this.isDialogueFinished = false,
  });

  // Хелпер-геттер для удобного доступа к данным текущего чекпоинта.
  Checkpoint get currentCheckpoint => quest.checkpoints[currentStep];
  
  // Хелпер-геттер для удобного доступа к данным текущей реплики.
  DialogueLine get currentDialogueLine =>
      currentCheckpoint.dialogue[currentDialogueIndex];

  /// Метод для создания копии состояния с измененными параметрами.
  /// Это основной способ изменения состояния в BLoC.
  QuestLoadSuccess copyWith({
    Quest? quest,
    int? currentStep,
    int? currentDialogueIndex,
    bool? isDialogueFinished,
  }) {
    return QuestLoadSuccess(
      quest: quest ?? this.quest,
      currentStep: currentStep ?? this.currentStep,
      currentDialogueIndex:
          currentDialogueIndex ?? this.currentDialogueIndex,
      isDialogueFinished: isDialogueFinished ?? this.isDialogueFinished,
    );
  }

  @override
  List<Object?> get props =>
      [quest, currentStep, currentDialogueIndex, isDialogueFinished];
}

/// Состояние, когда произошла ошибка при загрузке квеста.
/// UI может показать сообщение об ошибке.
class QuestLoadFailure extends QuestState {}

/// Состояние, когда квест полностью пройден.
/// UI может показать экран с поздравлениями.
class QuestCompleted extends QuestState {
  final Quest quest;
  const QuestCompleted({required this.quest});
  @override
  List<Object> get props => [quest];
}