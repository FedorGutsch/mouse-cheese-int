import 'package:equatable/equatable.dart';

// Модель для данных о персонаже, загружаемых из JSON
class Character {
  final Map<String, String> poses;
  final List<String> blinkAnimationFrames;

  const Character({required this.poses, required this.blinkAnimationFrames});

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      poses: Map<String, String>.from(json['poses']),
      blinkAnimationFrames: List<String>.from(json['blink_animation_frames']),
    );
  }
}

// Модель для всего квеста
class Quest extends Equatable {
  final String questId;
  final String questName;
  final Map<String, Character> characters;
  final List<Checkpoint> checkpoints;

  const Quest({
    required this.questId,
    required this.questName,
    required this.characters,
    required this.checkpoints,
  });

  // Фабричный конструктор для парсинга из JSON
  factory Quest.fromJson(Map<String, dynamic> json) {
    var checkpointsList = json['checkpoints'] as List;
    List<Checkpoint> checkpoints =
        checkpointsList.map((i) => Checkpoint.fromJson(i)).toList();

    var charactersMap = json['characters'] as Map<String, dynamic>;
    Map<String, Character> characters = charactersMap.map(
      (key, value) => MapEntry(key, Character.fromJson(value)),
    );

    return Quest(
      questId: json['questId'],
      questName: json['questName'],
      characters: characters,
      checkpoints: checkpoints,
    );
  }

  @override
  List<Object?> get props => [questId, questName, characters, checkpoints];
}

// Модель для одного шага (чекпоинта) в квесте
class Checkpoint extends Equatable {
  final int step;
  final Location location;
  final double triggerRadius;
  final List<DialogueLine> dialogue;

  const Checkpoint({
    required this.step,
    required this.location,
    required this.triggerRadius,
    required this.dialogue,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    var dialogueList = json['dialogue'] as List;
    List<DialogueLine> dialogue =
        dialogueList.map((i) => DialogueLine.fromJson(i)).toList();

    return Checkpoint(
      step: json['step'],
      location: Location.fromJson(json['location']),
      triggerRadius: json['triggerRadius'].toDouble(),
      dialogue: dialogue,
    );
  }

  @override
  List<Object?> get props => [step, location, triggerRadius, dialogue];
}

// Модель для GPS-координат
class Location extends Equatable {
  final double lat;
  final double lon;

  const Location({required this.lat, required this.lon});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: json['lat'].toDouble(),
      lon: json['lon'].toDouble(),
    );
  }

  @override
  List<Object?> get props => [lat, lon];
}

// Модель для одной реплики в диалоге
class DialogueLine extends Equatable {
  final String characterId;
  final String characterName;
  final String text;
  final String pose;

  const DialogueLine({
    required this.characterId,
    required this.characterName,
    required this.text,
    required this.pose,
  });

  factory DialogueLine.fromJson(Map<String, dynamic> json) {
    return DialogueLine(
      characterId: json['characterId'],
      characterName: json['characterName'],
      text: json['text'],
      pose: json['pose'],
    );
  }

  @override
  List<Object?> get props => [characterId, characterName, text, pose];
}