// lib/bloc/quest_list_state.dart

import 'package:equatable/equatable.dart';
import 'package:quest_app_new/data/models.dart';

abstract class QuestListState extends Equatable {
  const QuestListState();

  @override
  List<Object> get props => [];
}

class QuestListInitial extends QuestListState {}

class QuestListLoadInProgress extends QuestListState {}

class QuestListLoadSuccess extends QuestListState {
  final List<Quest> activeQuests;
  final List<Quest> completedQuests;

  const QuestListLoadSuccess({
    required this.activeQuests,
    required this.completedQuests,
  });

  @override
  List<Object> get props => [activeQuests, completedQuests];
}

class QuestListLoadFailure extends QuestListState {}