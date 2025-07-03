// lib/bloc/profile_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quest_app_new/data/models.dart';
import 'package:quest_app_new/data/progress_repository.dart';
import 'package:quest_app_new/data/quest_repository.dart';
import 'package:quest_app_new/bloc/profile_event.dart';
import 'package:quest_app_new/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProgressRepository progressRepository;
  final QuestRepository questRepository;

  static const String defaultAvatar = 'assets/images/guide_neutral.png';
  static const String networkAvatar = 'https://via.placeholder.com/150';

  ProfileBloc({
    required this.progressRepository,
    required this.questRepository,
  }) : super(ProfileInitial()) {
    on<ProfileLoadStarted>(_onProfileLoadStarted);
    on<ProfileAvatarChanged>(_onProfileAvatarChanged);
  }

  Future<void> _onProfileLoadStarted(
    ProfileLoadStarted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoadInProgress());
    try {
      final userProfile = progressRepository.loadUserProfile();
      final avatar = userProfile?.avatarPath ?? defaultAvatar;
      final completedQuests = userProfile?.completedQuests ?? [];
      
      final historyMap = userProfile?.dialogueHistory ?? {};
      final Map<String, List<DialogueLine>> dialogueHistory = {};
      historyMap.forEach((questId, dialoguesJson) {
        dialogueHistory[questId] = dialoguesJson
            .map((json) => DialogueLine.fromJson(json))
            .toList();
      });

      final allQuests = await questRepository.getAllQuests();

      emit(ProfileLoadSuccess(
        avatarPath: avatar,
        allQuests: allQuests,
        completedQuestIds: completedQuests,
        dialogueHistory: dialogueHistory,
      ));
    } catch (_) {
      emit(ProfileLoadFailure());
    }
  }

  Future<void> _onProfileAvatarChanged(
    ProfileAvatarChanged event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoadSuccess) {
      final newAvatar =
          currentState.avatarPath == defaultAvatar ? 'assets/images/guide_happy.png' : defaultAvatar;
      await progressRepository.saveAvatar(newAvatar);
      
      // --- ИСПРАВЛЕНИЕ ЗДЕСЬ ---
      // Мы должны передать ВСЕ обязательные поля, включая dialogueHistory
      emit(ProfileLoadSuccess(
        avatarPath: newAvatar,
        allQuests: currentState.allQuests,
        completedQuestIds: currentState.completedQuestIds,
        dialogueHistory: currentState.dialogueHistory, // Это поле было пропущено
      ));
    }
  }
}