// lib/data/quest_repository.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:quest_app_new/data/models.dart';

class QuestRepository {

  // --- ДОБАВЛЯЕМ НОВЫЙ МЕТОД ---
  Future<List<Quest>> getAllQuests() async {
    try {
      // 1. Загружаем манифест ассетов, который содержит пути ко всем файлам в assets.
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // 2. Фильтруем пути, оставляя только те, что ведут к нашим файлам с квестами.
      final questPaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/quests/'))
          .toList();

      // 3. Асинхронно загружаем и парсим каждый файл квеста.
      final List<Future<Quest>> futureQuests = questPaths.map((path) async {
        final jsonString = await rootBundle.loadString(path);
        final jsonMap = json.decode(jsonString);
        return Quest.fromJson(jsonMap);
      }).toList();

      // 4. Дожидаемся завершения всех загрузок и возвращаем список.
      return await Future.wait(futureQuests);

    } catch (e) {
      print('Error loading all quests: $e');
      throw Exception('Failed to load all quests');
    }
  }

  // Этот метод нам все еще нужен для загрузки конкретного квеста.
  Future<Quest> getQuestById(String questId) async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/quests/$questId.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return Quest.fromJson(jsonMap);
    } catch (e) {
      print('Error loading quest by ID: $e');
      throw Exception('Failed to load quest');
    }
  }
}