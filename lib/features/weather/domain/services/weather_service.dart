import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';

/// Contract for fetching live weather data.
abstract class WeatherService {
  Future<WeatherSnapshot> getWeather({
    required double latitude,
    required double longitude,
  });
}
