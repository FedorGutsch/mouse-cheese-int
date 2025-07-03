// lib/bloc/quest_list_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quest_app_new/bloc/quest_list_event.dart';
import 'package:quest_app_new/bloc/quest_list_state.dart';
import 'package:quest_app_new/data/progress_repository.dart';
import 'package:quest_app_new/data/quest_repository.dart';
import 'package:quest_app_new/data/models.dart';

class QuestListBloc extends Bloc<QuestListEvent, QuestListState> {
  final QuestRepository _questRepository;
  final ProgressRepository _progressRepository;

  QuestListBloc({
    required QuestRepository questRepository,
    required ProgressRepository progressRepository,
  })  : _questRepository = questRepository,
        _progressRepository = progressRepository,
        super(QuestListInitial()) {
    on<QuestListStarted>(_onQuestListStarted);
  }

  Future<void> _onQuestListStarted(
    QuestListStarted event,
    Emitter<QuestListState> emit,
  ) async {
    emit(QuestListLoadInProgress());
    try {
      final allQuests = await _questRepository.getAllQuests();
      final userProfile = _progressRepository.loadUserProfile();
      final completedQuestIds = userProfile?.completedQuests ?? [];

      final List<Quest> activeQuests = [];
      final List<Quest> completedQuests = [];

      for (final quest in allQuests) {
        if (completedQuestIds.contains(quest.questId)) {
          completedQuests.add(quest);
        } else {
          activeQuests.add(quest);
        }
      }

      emit(QuestListLoadSuccess(
        activeQuests: activeQuests,
        completedQuests: completedQuests,
      ));
    } catch (_) {
      emit(QuestListLoadFailure());
    }
  }
}