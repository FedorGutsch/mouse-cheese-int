import 'package:equatable/equatable.dart';
import 'package:quest_app_new/data/location_service.dart';

// Абстрактный базовый класс для всех событий.
// Equatable используется для удобного сравнения объектов.
abstract class QuestEvent extends Equatable {
  const QuestEvent();

  @override
  List<Object?> get props => [];
}

/// Событие, которое инициирует загрузку квеста.
/// Может быть вызвано как с конкретным ID квеста (новая игра),
/// так и с null (попытка продолжить сохраненную игру).
class QuestLoadRequested extends QuestEvent {
  final String? questId;

  const QuestLoadRequested(this.questId);

  @override
  List<Object?> get props => [questId];
}

/// Событие, которое запрашивает показ следующей реплики в диалоге.
/// Вызывается, когда пользователь нажимает на диалоговое окно.
class QuestDialogueAdvanced extends QuestEvent {}

/// Событие, которое сообщает, что игрок достиг цели (чекпоинта).
/// Вызывается внутренне, когда LocationService определяет, что
/// дистанция до цели меньше радиуса триггера.
class QuestCheckpointReached extends QuestEvent {}

class LocationStatusChanged extends QuestEvent {
  final LocationStatus status;
  const LocationStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

/// Событие от UI, которое просит BLoC повторить попытку получения разрешений.
class RetryLocationPermission extends QuestEvent {}