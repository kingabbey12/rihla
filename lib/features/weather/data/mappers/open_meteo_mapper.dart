import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';

/// Maps Open-Meteo JSON to domain weather models.
abstract final class OpenMeteoMapper {
  static WeatherSnapshot fromJson(
    Map<String, dynamic> json, {
    required double latitude,
    required double longitude,
  }) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final hourly = json['hourly'] as Map<String, dynamic>? ?? {};

    final observedAt = DateTime.tryParse(current['time'] as String? ?? '') ??
        DateTime.now();
    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;

    final currentConditions = WeatherConditions(
      latitude: latitude,
      longitude: longitude,
      temperatureCelsius:
          (current['temperature_2m'] as num?)?.toDouble() ?? 20,
      windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      visibilityMeters:
          (current['visibility'] as num?)?.toDouble() ?? 10000,
      rainProbabilityPercent:
          (current['precipitation_probability'] as num?)?.toDouble() ?? 0,
      uvIndex: (current['uv_index'] as num?)?.toDouble() ?? 0,
      summary: _summaryForCode(weatherCode),
      observedAt: observedAt,
      windDirectionDegrees:
          (current['wind_direction_10m'] as num?)?.toDouble(),
      humidityPercent:
          (current['relative_humidity_2m'] as num?)?.toDouble(),
    );

    final times = (hourly['time'] as List<dynamic>?) ?? [];
    final temps = (hourly['temperature_2m'] as List<dynamic>?) ?? [];
    final rain = (hourly['precipitation_probability'] as List<dynamic>?) ?? [];
    final uv = (hourly['uv_index'] as List<dynamic>?) ?? [];
    final wind = (hourly['wind_speed_10m'] as List<dynamic>?) ?? [];
    final codes = (hourly['weather_code'] as List<dynamic>?) ?? [];

    final forecast = <WeatherForecastEntry>[];
    for (var i = 0; i < times.length && i < 24; i++) {
      final time = DateTime.tryParse(times[i] as String? ?? '');
      if (time == null) continue;
      final code = (codes.elementAtOrNull(i) as num?)?.toInt() ?? 0;
      forecast.add(
        WeatherForecastEntry(
          time: time,
          temperatureCelsius: (temps.elementAtOrNull(i) as num?)?.toDouble() ?? 20,
          rainProbabilityPercent: (rain.elementAtOrNull(i) as num?)?.toDouble() ?? 0,
          uvIndex: (uv.elementAtOrNull(i) as num?)?.toDouble() ?? 0,
          windSpeedKmh: (wind.elementAtOrNull(i) as num?)?.toDouble() ?? 0,
          summary: _summaryForCode(code),
        ),
      );
    }

    return WeatherSnapshot(current: currentConditions, forecast: forecast);
  }

  static String _summaryForCode(int code) => switch (code) {
        0 => 'Clear skies',
        1 || 2 || 3 => 'Partly cloudy',
        45 || 48 => 'Fog',
        51 || 53 || 55 => 'Drizzle',
        61 || 63 || 65 => 'Rain',
        71 || 73 || 75 => 'Snow',
        80 || 81 || 82 => 'Rain showers',
        95 || 96 || 99 => 'Thunderstorm',
        _ => 'Variable conditions',
      };
}
