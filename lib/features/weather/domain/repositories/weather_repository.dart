import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';

/// High-level weather operations.
abstract class WeatherRepository {
  Future<WeatherSnapshot> getWeather({
    required double latitude,
    required double longitude,
  });
}
