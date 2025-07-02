// lib/bloc/quest_list_event.dart

import 'package:equatable/equatable.dart';

abstract class QuestListEvent extends Equatable {
  const QuestListEvent();

  @override
  List<Object> get props => [];
}

class QuestListStarted extends QuestListEvent {}