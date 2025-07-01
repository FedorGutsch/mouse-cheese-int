import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quest_app_new/bloc/quest_bloc.dart';
import 'package:quest_app_new/bloc/quest_event.dart';
import 'package:quest_app_new/bloc/quest_state.dart';
import 'package:quest_app_new/data/location_service.dart';
import 'package:quest_app_new/presentation/dialogue_view.dart';
import 'package:quest_app_new/presentation/screens/profile_screen.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  YandexMapController? _mapController;
  bool _isUserLayerEnabled = false;

  // --- ИЗМЕНЕНИЕ 1: Добавляем флаг готовности карты ---
  bool _isMapComponentReady = false;

  @override
  void initState() {
    super.initState();
    _initPermissions();
    context.read<QuestBloc>().add(const QuestLoadRequested(null));

    // --- ИЗМЕНЕНИЕ 2: Добавляем искусственную задержку ---
    // Даем нативной части время на инициализацию перед отрисовкой карты
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isMapComponentReady = true;
        });
      }
    });
  }

  Future<void> _initPermissions() async {
    final locationService = context.read<LocationService>();
    if (await locationService.handlePermission()) {
      if (mounted) {
        setState(() {
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Нет активных квестов.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<QuestBloc>()
                          .add(const QuestLoadRequested('city_tour'));
                    },
                    child: const Text('Начать новый квест'),
                  )
                ],
              ),
            );
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
                  image: BitmapDescriptor.fromAssetImage(checkpoint.markerIcon),
                  scale: 0.7,
                ),
              ),
            );

            return Stack(
              children: [
                // --- ИЗМЕНЕНИЕ 3: Оборачиваем карту в условие ---
                if (_isMapComponentReady)
                  YandexMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _mapController?.toggleUserLayer(visible: _isUserLayerEnabled);
                      
                      final point = Point(
                          latitude: checkpoint.location.lat,
                          longitude: checkpoint.location.lon);
                      _moveCameraTo(point);
                    },
                    mapObjects: [placemark],
                  )
                else
                  // Показываем заглушку, пока ждем
                  const Center(child: CircularProgressIndicator()),

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