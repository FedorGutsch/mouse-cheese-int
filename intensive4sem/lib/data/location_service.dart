import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Проверяет разрешения и запрашивает их при необходимости.
  /// Возвращает true, если разрешения получены.
  Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Проверяем, включен ли сервис геолокации на устройстве.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Сервисы геолокации отключены, не можем продолжать.
      // В реальном приложении здесь стоит показать пользователю диалог
      // с просьбой включить геолокацию.
      print('Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Пользователь отказал в доступе.
        print('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Пользователь навсегда отказал в доступе, запросить снова нельзя.
      print(
          'Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }

    // Если мы дошли сюда, значит все разрешения получены.
    return true;
  }

  /// Возвращает поток (Stream) с обновлениями позиции пользователя.
  Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Высокая точность для навигации
      distanceFilter: 10, // Сообщать об изменении, если пройдено 10 метров
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Рассчитывает дистанцию в метрах между двумя GPS-координатами.
  double getDistance(
      double startLat, double startLon, double endLat, double endLon) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }
}