import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';
import 'package:rihla/features/weather/domain/repositories/weather_repository.dart';
import 'package:rihla/features/weather/domain/services/weather_service.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl(this._service);

  final WeatherService _service;

  @override
  Future<WeatherSnapshot> getWeather({
    required double latitude,
    required double longitude,
  }) =>
      _service.getWeather(latitude: latitude, longitude: longitude);
}
