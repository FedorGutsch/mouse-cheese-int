import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quest_app/bloc/quest_bloc.dart';
import 'package:quest_app/bloc/quest_state.dart';
import 'package:quest_app/data/models.dart';
import 'package:quest_app/presentation/widgets/character_view.dart';

class DialogueView extends StatefulWidget {
  final DialogueLine dialogueLine;

  const DialogueView({super.key, required this.dialogueLine});

  @override
  State<DialogueView> createState() => _DialogueViewState();
}

class _DialogueViewState extends State<DialogueView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Получаем текущее состояние квеста, чтобы достать данные о персонаже
    final questState = context.read<QuestBloc>().state;
    if (questState is! QuestLoadSuccess) {
      return const SizedBox.shrink(); // Безопасная заглушка
    }

    final characterData =
        questState.quest.characters[widget.dialogueLine.characterId]!;
    String poseKey = widget.dialogueLine.pose;

    // Реализуем логику для случайной позы
    if (poseKey == 'random') {
      final availablePoses = characterData.poses.keys.toList();
      poseKey = availablePoses[Random().nextInt(availablePoses.length)];
    }

    final baseSpritePath = characterData.poses[poseKey]!;
    final blinkFrames = characterData.blinkAnimationFrames;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Используем наш кастомный виджет для персонажа
                  CharacterView(
                    baseSprite: baseSpritePath,
                    blinkAnimationFrames: blinkFrames,
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.dialogueLine.characterName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.dialogueLine.text,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Анимированный индикатор "продолжить"
            Positioned(
              bottom: 0,
              right: 20,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.black54,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}