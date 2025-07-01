import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quest_app_new/bloc/quest_event.dart';
import 'package:quest_app_new/bloc/quest_state.dart';
import 'package:quest_app_new/data/location_service.dart';
import 'package:quest_app_new/data/progress_repository.dart';
import 'package:quest_app_new/data/quest_repository.dart';

class QuestBloc extends Bloc<QuestEvent, QuestState>{
  final QuestRepository questRepository;
  final LocationService locationService;
  final ProgressRepository progressRepository;

  StreamSubscription<Position>? _positionSubscription;

  QuestBloc({
    required this.questRepository,
    required this.locationService,
    required this.progressRepository,
  }) : super(QuestInitial()) {
    on<QuestLoadRequested>(_onQuestLoadRequested);
    on<QuestDialogueAdvanced>(_onQuestDialogueAdvanced);
    on<QuestCheckpointReached>(_onQuestCheckpointReached);
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }

  Future<void> _onQuestLoadRequested(
    QuestLoadRequested event,
    Emitter<QuestState> emit,
  ) async {
    emit(QuestLoadInProgress());
    try {
      final savedProgress = progressRepository.loadCurrentQuestState();
      final questToLoadId = event.questId ?? savedProgress?.currentQuestId;

      if (questToLoadId == null) {
        // Нет ни нового, ни сохраненного квеста.
        emit(QuestLoadFailure());
        return;
      }

      final quest = await questRepository.getQuestById(questToLoadId);

      if (savedProgress != null && savedProgress.currentQuestId == questToLoadId) {
        final checkpoint = quest.checkpoints[savedProgress.currentStep!];
        final isDialogueFinished = (savedProgress.currentDialogueIndex! + 1) >= checkpoint.dialogue.length;

        final loadedState = QuestLoadSuccess(
          quest: quest,
          currentStep: savedProgress.currentStep!,
          currentDialogueIndex: savedProgress.currentDialogueIndex!,
          isDialogueFinished: isDialogueFinished,
        );
        emit(loadedState);
        if (isDialogueFinished) {
          _startTracking(loadedState);
        }
      } else {
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
        final newState = currentState.copyWith(currentDialogueIndex: nextDialogueIndex);
        emit(newState);
        _saveProgress(newState);
      } else {
        final newState = currentState.copyWith(isDialogueFinished: true);
        emit(newState);
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
        // Квест завершен!
        progressRepository.addCompletedQuest(currentState.quest.questId);
        progressRepository.clearCurrentQuestState();
        emit(QuestCompleted(quest: currentState.quest));
      }
    }
  }

  void _startTracking(QuestLoadSuccess state) {
    print("[DEBUG] Вызван метод _startTracking. Начинаем слушать GPS.");
    _positionSubscription?.cancel();
    _positionSubscription = locationService.getPositionStream().listen((position) {
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
    await progressRepository.saveCurrentQuestState(
      state.quest.questId,
      state.currentStep,
      state.currentDialogueIndex,
    );
  }
}