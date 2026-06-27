import 'package:rihla/features/weather/data/datasources/open_meteo_datasource.dart';
import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';
import 'package:rihla/features/weather/domain/services/weather_service.dart';

/// Production weather service using Open-Meteo.
class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService(this._datasource);

  final OpenMeteoDatasource _datasource;

  @override
  Future<WeatherSnapshot> getWeather({
    required double latitude,
    required double longitude,
  }) =>
      _datasource.fetch(latitude: latitude, longitude: longitude);
}
