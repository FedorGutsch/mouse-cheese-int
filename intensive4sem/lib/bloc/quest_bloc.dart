import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quest_app/bloc/quest_event.dart';
import 'package:quest_app/bloc/quest_state.dart';
import 'package:quest_app/data/location_service.dart';
import 'package:quest_app/data/progress_model.dart';
import 'package:quest_app/data/progress_repository.dart';
import 'package:quest_app/data/quest_repository.dart';

class QuestBloc extends Bloc<QuestEvent, QuestState> {
  final QuestRepository questRepository;
  final LocationService locationService;
  final ProgressRepository progressRepository;

  StreamSubscription<Position>? _positionSubscription;

  QuestBloc({
    required this.questRepository,
    required this.locationService,
    required this.progressRepository,
  }) : super(QuestInitial()) {
    // Регистрация обработчиков для каждого события
    on<QuestLoadRequested>(_onQuestLoadRequested);
    on<QuestDialogueAdvanced>(_onQuestDialogueAdvanced);
    on<QuestCheckpointReached>(_onQuestCheckpointReached);
  }

  @override
  Future<void> close() {
    // Важно отменять подписку при уничтожении BLoC, чтобы избежать утечек памяти
    _positionSubscription?.cancel();
    return super.close();
  }

  // lib/bloc/quest_bloc.dart

  Future<void> _onQuestLoadRequested(
    QuestLoadRequested event,
    Emitter<QuestState> emit,
  ) async {
    emit(QuestLoadInProgress());
    try {
      QuestProgress? savedProgress = progressRepository.loadProgress();
      String? questToLoadId = event.questId ?? savedProgress?.questId;

      if (questToLoadId == null) {
        emit(QuestLoadFailure());
        return;
      }

      final quest = await questRepository.getQuestById(questToLoadId);

      if (savedProgress != null && savedProgress.questId == questToLoadId) {
        // --- УЛУЧШЕННАЯ ЛОГИКА ---
        // Определяем, был ли диалог завершен, на основе сохраненных данных
        final checkpoint = quest.checkpoints[savedProgress.currentStep];
        final bool isDialogueFinished =
            savedProgress.currentDialogueIndex + 1 >= checkpoint.dialogue.length;

        // Создаем состояние со всеми правильными параметрами
        final loadedState = QuestLoadSuccess(
          quest: quest,
          currentStep: savedProgress.currentStep,
          currentDialogueIndex: savedProgress.currentDialogueIndex,
          isDialogueFinished: isDialogueFinished,
        );
        
        emit(loadedState);

        // Если диалог был завершен, сразу начинаем отслеживание
        if (isDialogueFinished) {
          _startTracking(loadedState);
        }
      } else {
        // Начинаем новый квест
        final initialState = QuestLoadSuccess(quest: quest);
        emit(initialState);
        _saveProgress(initialState);
      }
    } catch (e) {
      print("[ERROR] Ошибка при загрузке квеста: $e");
      emit(QuestLoadFailure());
    }
  }

  void _onQuestDialogueAdvanced(
    QuestDialogueAdvanced event,
    Emitter<QuestState> emit,
  ) {
    final currentState = state;
    if (currentState is QuestLoadSuccess) {
      final currentDialogue = currentState.currentCheckpoint.dialogue;
      final nextDialogueIndex = currentState.currentDialogueIndex + 1;

      if (nextDialogueIndex < currentDialogue.length) {
        final newState =
            currentState.copyWith(currentDialogueIndex: nextDialogueIndex);
        emit(newState);
        _saveProgress(newState);
      } else {
        final newState = currentState.copyWith(isDialogueFinished: true);
        emit(newState);
        _saveProgress(newState);
        _startTracking(newState);
      }
    }
  }

  void _onQuestCheckpointReached(
    QuestCheckpointReached event,
    Emitter<QuestState> emit,
  ) {
    final currentState = state;
    if (currentState is QuestLoadSuccess) {
      _positionSubscription?.cancel();
      _positionSubscription = null;

      final nextStep = currentState.currentStep + 1;

      if (nextStep < currentState.quest.checkpoints.length) {
        final newState = currentState.copyWith(
          currentStep: nextStep,
          currentDialogueIndex: 0,
          isDialogueFinished: false,
        );
        emit(newState);
        _saveProgress(newState);
      } else {
        emit(QuestCompleted(quest: currentState.quest));
        progressRepository.clearProgress();
      }
    }
  }

  // lib/bloc/quest_bloc.dart

  void _startTracking(QuestLoadSuccess state) {
    print("[DEBUG] Вызван метод _startTracking. Начинаем слушать GPS.");
    _positionSubscription?.cancel();
    _positionSubscription = locationService.getPositionStream().listen((position) {
      // Если вы видите это сообщение, значит GPS работает!
      print("[DEBUG] Получена новая позиция: ${position.latitude}, ${position.longitude}");
      
      final checkpoint = state.currentCheckpoint;
      final distance = locationService.getDistance(
        position.latitude,
        position.longitude,
        checkpoint.location.lat,
        checkpoint.location.lon,
      );

      print('[DEBUG] Дистанция до чекпоинта: $distance метров');

      if (distance <= checkpoint.triggerRadius) {
        print("[DEBUG] Игрок достиг цели! Отправляем событие QuestCheckpointReached.");
        add(QuestCheckpointReached());
      }
    });
  }

  Future<void> _saveProgress(QuestLoadSuccess state) async {
    final progress = QuestProgress()
      ..questId = state.quest.questId
      ..currentStep = state.currentStep
      ..currentDialogueIndex = state.currentDialogueIndex;
    await progressRepository.saveProgress(progress);
  }
}