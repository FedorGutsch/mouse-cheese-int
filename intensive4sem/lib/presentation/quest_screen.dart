import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quest_app/bloc/quest_bloc.dart';
import 'package:quest_app/bloc/quest_event.dart';
import 'package:quest_app/bloc/quest_state.dart';
import 'package:quest_app/data/location_service.dart';
import 'package:quest_app/presentation/dialogue_view.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  YandexMapController? _mapController;
  bool _userLocationLayerVisible = false;

  @override
  void initState() {
    super.initState();
    _initPermissions();
    // При старте экрана отправляем событие на загрузку квеста.
    // Передаем ID квеста по умолчанию. BLoC сам разберется,
    // нужно ли загружать сохраненный прогресс или начинать заново.
    context.read<QuestBloc>().add(const QuestLoadRequested('city_tour'));
  }

  // Метод для запроса разрешений на геолокацию при старте.
 // lib/presentation/quest_screen.dart

  Future<void> _initPermissions() async {
    print("[DEBUG] Инициализация разрешений...");
    final locationService = context.read<LocationService>();
    if (await locationService.handlePermission()) {
      print("[DEBUG] Разрешения на геолокацию ПОЛУЧЕНЫ.");
      if (mounted) {
        setState(() {
          _userLocationLayerVisible = true;
        });
      }
    } else {
      print("[DEBUG] Разрешения на геолокацию ОТКЛОНЕНЫ.");
    }
  }

  // Хелпер для плавного перемещения камеры карты.
  void _moveCameraTo(Point point, {double zoom = 15.0}) {
    _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: zoom),
      ),
      animation: const MapAnimation(type: MapAnimationType.smooth, duration: 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<QuestBloc, QuestState>(
        // listener используется для действий, которые нужно выполнить один раз,
        // например, навигация или показ SnackBar. Здесь мы двигаем камеру.
        listener: (context, state) {
          if (state is QuestLoadSuccess) {
            final checkpointLocation = state.currentCheckpoint.location;
            final point = Point(
                latitude: checkpointLocation.lat,
                longitude: checkpointLocation.lon);
            _moveCameraTo(point);
          }
        },
        // builder используется для построения виджетов на основе состояния.
        builder: (context, state) {
          // Показываем разные UI для разных состояний
          if (state is QuestCompleted) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Поздравляем!',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Квест "${state.quest.questName}" пройден!',
                      style: const TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          if (state is QuestLoadInProgress || state is QuestInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is QuestLoadFailure) {
            return const Center(child: Text('Не удалось загрузить квест.'));
          }

          if (state is QuestLoadSuccess) {
            final checkpoint = state.currentCheckpoint;
            final placemark = PlacemarkMapObject(
              mapId: const MapObjectId('quest_placemark'),
              point: Point(
                  latitude: checkpoint.location.lat,
                  longitude: checkpoint.location.lon),
              icon: PlacemarkIcon.single(
                PlacemarkIconStyle(
                  image: BitmapDescriptor.fromAssetImage(
                      'assets/images/placemark.png'),
                  scale: 0.5,
                ),
              ),
            );

            return Stack(
              children: [
                YandexMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _mapController?.toggleUserLayer(
                        visible: _userLocationLayerVisible);
                    // Если карта создалась, а BLoC уже в нужном состоянии,
                    // дополнительно двигаем камеру.
                    final point = Point(
                        latitude: checkpoint.location.lat,
                        longitude: checkpoint.location.lon);
                    _moveCameraTo(point);
                  },
                  mapObjects: [placemark],
                ),

                // Показываем диалог и затемнение только если он НЕ завершен
                if (!state.isDialogueFinished)
                  GestureDetector(
                    onTap: () {
                      // При тапе по области диалога отправляем событие в BLoC
                      context.read<QuestBloc>().add(QuestDialogueAdvanced());
                    },
                    child: Stack(
                      children: [
                        Container(
                          color: Colors.black.withOpacity(0.3),
                        ),
                        DialogueView(dialogueLine: state.currentDialogueLine),
                      ],
                    ),
                  ),
              ],
            );
          }
          // Возвращаем пустой контейнер на случай непредвиденного состояния
          return const SizedBox.shrink();
        },
      ),
    );
  }
}