import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quest_app/bloc/quest_bloc.dart';
import 'package:quest_app/data/location_service.dart';
import 'package:quest_app/data/progress_model.dart';
import 'package:quest_app/data/progress_repository.dart';
import 'package:quest_app/data/quest_repository.dart';
import 'package:quest_app/presentation/quest_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  Hive.registerAdapter(QuestProgressAdapter());

  // Создаем экземпляр репозитория
  final progressRepository = ProgressRepository();
  await progressRepository.init();

  // ИСПРАВЛЕНИЕ: Передаем созданный репозиторий в MyApp
  runApp(MyApp(progressRepository: progressRepository));
}

class MyApp extends StatelessWidget {
  // Добавляем поле для хранения репозитория
  final ProgressRepository progressRepository;

  // ИСПРАВЛЕНИЕ: Добавляем репозиторий в конструктор
  const MyApp({super.key, required this.progressRepository});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Используем .value, так как экземпляр уже создан
        RepositoryProvider.value(value: progressRepository),
        RepositoryProvider(create: (context) => QuestRepository()),
        RepositoryProvider(create: (context) => LocationService()),
      ],
      child: BlocProvider(
        create: (context) => QuestBloc(
          questRepository: context.read<QuestRepository>(),
          locationService: context.read<LocationService>(),
          progressRepository: context.read<ProgressRepository>(),
        ),
        child: MaterialApp(
          title: 'Quest App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          debugShowCheckedModeBanner: false,
          home: const QuestScreen(),
        ),
      ),
    );
  }
}