import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/network/api_client.dart';
import 'package:rihla/core/network/api_exception.dart';
import 'package:rihla/features/weather/data/mappers/open_meteo_mapper.dart';
import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';
import 'package:rihla/features/weather/domain/errors/weather_failure.dart';

/// Open-Meteo weather API datasource (no API key required).
class OpenMeteoDatasource {
  OpenMeteoDatasource(this._client, {String? baseUrl})
      : _baseUrl = baseUrl ?? ApiConfig.openMeteoBaseUrl;

  final ApiClient _client;
  final String _baseUrl;

  Future<WeatherSnapshot> fetch({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$_baseUrl/v1/forecast').replace(
      queryParameters: {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'current': [
          'temperature_2m',
          'relative_humidity_2m',
          'wind_speed_10m',
          'wind_direction_10m',
          'visibility',
          'precipitation_probability',
          'uv_index',
          'weather_code',
        ].join(','),
        'hourly': [
          'temperature_2m',
          'precipitation_probability',
          'uv_index',
          'wind_speed_10m',
          'weather_code',
        ].join(','),
        'forecast_days': '2',
        'timezone': 'auto',
      },
    );

    try {
      final response = await _client.get(
        uri,
        cacheTtl: const Duration(minutes: 15),
        cacheKey: 'weather_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}',
      );
      return OpenMeteoMapper.fromJson(
        response.jsonObject(),
        latitude: latitude,
        longitude: longitude,
      );
    } on ApiOfflineException {
      throw const WeatherOfflineFailure();
    } on ApiException catch (e) {
      throw WeatherServiceFailure(e.message);
    }
  }
}
