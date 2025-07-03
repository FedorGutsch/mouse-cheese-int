// lib/bloc/quest_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quest_app_new/bloc/quest_event.dart';
import 'package:quest_app_new/bloc/quest_state.dart';
import 'package:quest_app_new/data/effects_service.dart';
import 'package:quest_app_new/data/location_service.dart';
import 'package:quest_app_new/data/progress_repository.dart';
import 'package:quest_app_new/data/quest_repository.dart';
import 'package:quest_app_new/data/models.dart';

class QuestBloc extends Bloc<QuestEvent, QuestState>{
  final QuestRepository questRepository;
  final LocationService locationService;
  final ProgressRepository progressRepository;
  final EffectsService effectsService;

  // --- ИСПРАВЛЕНИЕ: ПРАВИЛЬНОЕ ИМЯ ПЕРЕМЕННОЙ ---
  StreamSubscription<LocationStatus>? _locationStatusSubscription;

  QuestBloc({
    required this.questRepository,
    required this.locationService,
    required this.progressRepository,
    required this.effectsService,
  }) : super(QuestInitial()) {
    on<QuestLoadRequested>(_onQuestLoadRequested);
    on<QuestDialogueAdvanced>(_onQuestDialogueAdvanced);
    on<QuestCheckpointReached>(_onQuestCheckpointReached);
    // --- ИСПРАВЛЕНИЕ: ИСПОЛЬЗУЕМ ПУБЛИЧНОЕ ИМЯ СОБЫТИЯ ---
    on<LocationStatusChanged>(_onLocationStatusChanged);
    on<RetryLocationPermission>(_onRetryLocationPermission);
  }

  @override
  Future<void> close() {
    // --- ИСПРАВЛЕНИЕ: ПРАВИЛЬНОЕ ИМЯ ПЕРЕМЕННОЙ ---
    _locationStatusSubscription?.cancel();
    return super.close();
  }

  void _onQuestLoadRequested(
    QuestLoadRequested event,
    Emitter<QuestState> emit,
  ) async {
    emit(QuestLoadInProgress());
    try {
      final savedProgress = progressRepository.loadCurrentQuestState();
      final questToLoadId = event.questId ?? savedProgress?.currentQuestId;

      if (questToLoadId == null) {
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
      effectsService.playCheckpointComplete();
      
      _locationStatusSubscription?.cancel();
      _locationStatusSubscription = null;

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
        final quest = currentState.quest;
        final allDialogues = quest.checkpoints
            .expand((checkpoint) => checkpoint.dialogue)
            .toList();
        
        progressRepository.addCompletedQuest(quest.questId, allDialogues);
        progressRepository.clearCurrentQuestState();
        emit(QuestCompleted(quest: currentState.quest));
      }
    }
  }

  void _startTracking(QuestLoadSuccess state) {
    print("[DEBUG] Вызван метод _startTracking. Начинаем слушать статус геолокации.");
    _locationStatusSubscription?.cancel();
    _locationStatusSubscription = locationService.getLocationStatusStream().listen((status) {
      add(LocationStatusChanged(status));
    });
  }

  // --- ИСПРАВЛЕНИЕ: ИСПОЛЬЗУЕМ ПУБЛИЧНОЕ ИМЯ СОБЫТИЯ ---
  void _onLocationStatusChanged(LocationStatusChanged event, Emitter<QuestState> emit) {
    final currentState = state;
    if (currentState is QuestLoadSuccess) {
      switch (event.status.type) {
        case LocationStatusType.hasPosition:
          final position = event.status.position!;
          print("[DEBUG] Получена новая позиция: ${position.latitude}, ${position.longitude}");
          
          final checkpoint = currentState.currentCheckpoint;
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
          break;
        case LocationStatusType.serviceDisabled:
          emit(QuestLocationServiceDisabled(quest: currentState.quest, currentStep: currentState.currentStep));
          break;
        case LocationStatusType.permissionDenied:
        case LocationStatusType.permissionPermanentlyDenied:
          emit(QuestLocationPermissionDenied(quest: currentState.quest, currentStep: currentState.currentStep));
          break;
      }
    }
  }

  Future<void> _onRetryLocationPermission(RetryLocationPermission event, Emitter<QuestState> emit) async {
    final permission = await locationService.requestPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      final currentState = state;
      if (currentState is QuestLoadSuccess) {
        final newState = QuestLoadSuccess(
          quest: currentState.quest,
          currentStep: currentState.currentStep,
          currentDialogueIndex: currentState.currentDialogueIndex,
          isDialogueFinished: true,
        );
        emit(newState);
        _startTracking(newState);
      }
    }
  }
  
  Future<void> _saveProgress(QuestLoadSuccess state) async {
    await progressRepository.saveCurrentQuestState(
      state.quest.questId,
      state.currentStep,
      state.currentDialogueIndex,
    );
  }
}