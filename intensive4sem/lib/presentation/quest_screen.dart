import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quest_app/bloc/quest_bloc.dart';
import 'package:quest_app/bloc/quest_event.dart';
import 'package:quest_app/bloc/quest_state.dart';
import 'package:quest_app/data/location_service.dart';
import 'package:quest_app/presentation/dialogue_view.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';



// --- ВОТ НЕДОСТАЮЩИЙ ИМПОРТ ---
import 'package:quest_app_new/presentation/screens/profile_screen.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  YandexMapController? _mapController;
  // --- ИЗМЕНЕНИЕ 1: Переименовываем флаг для ясности ---
  bool _isUserLayerEnabled = false;

  @override
  void initState() {
    super.initState();
    _initPermissions();
    context.read<QuestBloc>().add(const QuestLoadRequested('city_tour'));
  }

  Future<void> _initPermissions() async {
    final locationService = context.read<LocationService>();
    if (await locationService.handlePermission()) {
      if (mounted) {
        setState(() {
          // --- ИЗМЕНЕНИЕ 2: Включаем флаг и пытаемся включить слой ---
          _isUserLayerEnabled = true;
          _mapController?.toggleUserLayer(visible: _isUserLayerEnabled);
        });
      }
    }
  }

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
      // --- ВОЗВРАЩАЕМ КНОПКУ ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
        child: const Icon(Icons.person),
      ),
      body: BlocConsumer<QuestBloc, QuestState>(
        listener: (context, state) {
          if (state is QuestLoadSuccess) {
            final checkpointLocation = state.currentCheckpoint.location;
            final point = Point(
                latitude: checkpointLocation.lat,
                longitude: checkpointLocation.lon);
            _moveCameraTo(point);
          }
        },
        builder: (context, state) {
          if (state is QuestCompleted) {
            // ... без изменений
          }

          if (state is QuestLoadInProgress || state is QuestInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is QuestLoadFailure) {
            return const Center(child: Text('Не удалось загрузить квест.'));
          }

          if (state is QuestLoadSuccess) {
            final checkpoint = state.currentCheckpoint;
            
            // --- ИЗМЕНЕНИЕ 3: Создаем кастомную метку ---
            final placemark = PlacemarkMapObject(
              mapId: const MapObjectId('quest_placemark'),
              point: Point(
                  latitude: checkpoint.location.lat,
                  longitude: checkpoint.location.lon),
              icon: PlacemarkIcon.single(
                PlacemarkIconStyle(
                  // Используем путь к иконке из нашего JSON
                  image: BitmapDescriptor.fromAssetImage(checkpoint.markerIcon),
                  scale: 0.7, // Можете настроить размер
                ),
              ),
            );

            return Stack(
              children: [
                YandexMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // --- ИЗМЕНЕНИЕ 4: Включаем слой пользователя при создании карты ---
                    _mapController?.toggleUserLayer(visible: _isUserLayerEnabled);
                    
                    final point = Point(
                        latitude: checkpoint.location.lat,
                        longitude: checkpoint.location.lon);
                    _moveCameraTo(point);
                  },
                  mapObjects: [placemark], // Передаем нашу кастомную метку
                ),
                if (!state.isDialogueFinished)
                  GestureDetector(
                    onTap: () {
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
          return const SizedBox.shrink();
        },
      ),
    );
  }
}