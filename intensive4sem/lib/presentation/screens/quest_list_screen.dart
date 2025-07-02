// lib/presentation/screens/quest_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quest_app_new/bloc/quest_bloc.dart';
import 'package:quest_app_new/bloc/quest_event.dart';
import 'package:quest_app_new/bloc/quest_list_bloc.dart';
import 'package:quest_app_new/bloc/quest_list_event.dart';
import 'package:quest_app_new/bloc/quest_list_state.dart';
import 'package:quest_app_new/data/models.dart';
import 'package:quest_app_new/data/progress_repository.dart';
import 'package:quest_app_new/data/quest_repository.dart';

class QuestListScreen extends StatelessWidget {
  const QuestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuestListBloc(
        questRepository: context.read<QuestRepository>(),
        progressRepository: context.read<ProgressRepository>(),
      )..add(QuestListStarted()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Задания'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: BlocBuilder<QuestListBloc, QuestListState>(
          builder: (context, state) {
            if (state is QuestListLoadInProgress) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is QuestListLoadSuccess) {
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionHeader('Активные', state.activeQuests.length),
                  ...state.activeQuests.map((quest) => _QuestCard(quest: quest)),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Завершенные', state.completedQuests.length),
                  ...state.completedQuests.map((quest) => _QuestCard(quest: quest, isCompleted: true)),
                ],
              );
            }
            if (state is QuestListLoadFailure) {
              return const Center(child: Text('Не удалось загрузить квесты.'));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final bool isCompleted;

  const _QuestCard({required this.quest, this.isCompleted = false});

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isCompleted ? Colors.grey : const Color(0xFFE61E79);

    // Предполагаем, что у каждого квеста есть картинка в `assets/images/`
    // с именем `{questId}_cover.png`. Если нет, можно добавить поле в `models.dart`.
    final String coverImage = 'assets/images/${quest.questId}_cover.png';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        // --- Заголовок карточки ---
        title: Text(quest.questName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Краткое описание квеста, чтобы..."), // Заглушка
        leading: CircleAvatar(
          backgroundColor: accentColor,
          child: const Icon(Icons.location_pin, color: Colors.white, size: 24),
        ),
        // --- Содержимое карточки ---
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    coverImage,
                    height: 150,
                    fit: BoxFit.cover,
                    // Обработка ошибки, если картинка не найдена
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Описание квеста, какая-то завязка в тексте, которая дает намек о сути, месте и прочем происходящем. Текста здесь должно быть больше чем в описании, но не много.",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                if (!isCompleted)
                  ElevatedButton(
                    onPressed: () {
                      // --- ШАГ 4: ИНТЕГРАЦИЯ ---
                      // 1. Отправляем событие в QuestBloc, чтобы он загрузил этот квест
                      context.read<QuestBloc>().add(QuestLoadRequested(quest.questId));

                      // 2. Показываем пользователю сообщение
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Квест начат! Перейдите на вкладку "Главная"'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Начать задание', style: TextStyle(fontSize: 16)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}