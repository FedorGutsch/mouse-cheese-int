// lib/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quest_app_new/bloc/profile_bloc.dart';
import 'package:quest_app_new/bloc/profile_event.dart';
import 'package:quest_app_new/bloc/profile_state.dart';
import 'package:quest_app_new/data/progress_repository.dart';
// --- ИСПРАВЛЕНИЕ ЗДЕСЬ: точка заменена на двоеточие ---
import 'package:quest_app_new/data/quest_repository.dart'; 
import 'package:quest_app_new/data/models.dart'; // Добавим импорт моделей на всякий случай

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(
        progressRepository: context.read<ProgressRepository>(),
        // Теперь компилятор знает, что такое QuestRepository
        questRepository: context.read<QuestRepository>(),
      )..add(ProfileLoadStarted()),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой Профиль'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProfileLoadFailure) {
            return const Center(child: Text('Не удалось загрузить профиль.'));
          }
          if (state is ProfileLoadSuccess) {
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildProfileHeader(state),
                const SizedBox(height: 24),
                _buildStats(state),
                const SizedBox(height: 24),
                _buildXpBar(state),
                const SizedBox(height: 32),
                _buildSectionTitle('Недавние квесты', 'Все'),
                const Center(child: Text('Список недавних квестов в разработке')),
                const SizedBox(height: 32),
                _buildSectionTitle('История диалогов', ''),
                _buildDialogueHistory(context, state),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProfileHeader(ProfileLoadSuccess state) {
    // Простая проверка, чтобы избежать ошибки, если ассет не найден
    final imageProvider = AssetImage(state.avatarPath);
    
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: imageProvider,
          onBackgroundImageError: (_, __) {}, // Пустой обработчик ошибок
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Имя Фамилия',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Lvl. 11',
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(ProfileLoadSuccess state) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${state.completedQuestIds.length}',
            label: 'Выполнено',
            icon: Icons.check_circle,
            color: Colors.pink,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _StatCard(
            value: '32км',
            label: 'Пройдено',
            icon: Icons.directions_walk,
            color: Colors.pink,
          ),
        ),
      ],
    );
  }

  Widget _buildXpBar(ProfileLoadSuccess state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: const LinearProgressIndicator(
            value: 0.5,
            minHeight: 8,
            backgroundColor: Color(0xFFFCE4EC),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('120/240 XP', style: TextStyle(color: Colors.grey)),
            Text('Lvl. 12', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildSectionTitle(String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (actionText.isNotEmpty)
          TextButton(
            onPressed: () {},
            child: Text(actionText, style: const TextStyle(color: Colors.pink)),
          ),
      ],
    );
  }

  Widget _buildDialogueHistory(BuildContext context, ProfileLoadSuccess state) {
    final characters = <String, Map<String, String>>{}; // {id: {name: name, avatar: path}}

    // Собираем всех уникальных персонажей из истории
    state.dialogueHistory.values.expand((d) => d).forEach((dialogue) {
      if (!characters.containsKey(dialogue.characterId)) {
        final characterData = state.allQuests
            .expand((q) => q.characters.entries)
            .firstWhere((entry) => entry.key == dialogue.characterId, orElse: () => const MapEntry('', Character(poses: {}, blinkAnimationFrames: [])))
            .value;
        
        characters[dialogue.characterId] = {
          'name': dialogue.characterName,
          'avatar': characterData.poses['neutral'] ?? 'assets/images/guide_neutral.png',
        };
      }
    });

    if (characters.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('Вы еще ни с кем не говорили.', style: TextStyle(color: Colors.grey))),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: characters.length,
        itemBuilder: (context, index) {
          final characterData = characters.values.elementAt(index);
          final avatarPath = characterData['avatar']!;
          final name = characterData['name']!;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 12.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: AssetImage(avatarPath),
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(height: 8),
                Text(name),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}