import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/traffic/data/mappers/traffic_mapper.dart';
import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';
import 'package:rihla/features/weather/data/mappers/open_meteo_mapper.dart';

void main() {
  test('OpenMeteoMapper parses current conditions', () {
    final snapshot = OpenMeteoMapper.fromJson(
      {
        'current': {
          'time': '2026-06-27T12:00',
          'temperature_2m': 32.5,
          'relative_humidity_2m': 40,
          'wind_speed_10m': 12,
          'wind_direction_10m': 180,
          'visibility': 8000,
          'precipitation_probability': 10,
          'uv_index': 7,
          'weather_code': 0,
        },
        'hourly': {
          'time': ['2026-06-27T13:00'],
          'temperature_2m': [33],
          'precipitation_probability': [15],
          'uv_index': [8],
          'wind_speed_10m': [14],
          'weather_code': [1],
        },
      },
      latitude: 24.7,
      longitude: 46.7,
    );

    expect(snapshot.current.summary, 'Clear skies');
    expect(snapshot.current.temperatureCelsius, 32.5);
    expect(snapshot.forecast, isNotEmpty);
  });

  test('TrafficMapper heuristic produces delay for congestion', () {
    final snapshot = TrafficMapper.heuristic(
      freeFlowDurationMinutes: 30,
      congestionFactor: 1.4,
    );

    expect(snapshot.density, isNot(TrafficDensity.freeFlow));
    expect(snapshot.travelDelayMinutes, greaterThan(0));
  });
}
