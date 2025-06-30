import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:quest_app/data/models.dart';

class QuestRepository {
  Future<Quest> getQuestById(String questId) async {
    try {
      // Загружаем строковое содержимое JSON файла из папки assets
      final String jsonString =
          await rootBundle.loadString('assets/quests/$questId.json');

      // Декодируем JSON строку в Map
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      // Создаем объект Quest из Map с помощью фабричного конструктора
      return Quest.fromJson(jsonMap);
    } catch (e) {
      // В реальном приложении здесь должна быть более сложная обработка ошибок
      print('Error loading quest: $e');
      throw Exception('Failed to load quest');
    }
  }
}