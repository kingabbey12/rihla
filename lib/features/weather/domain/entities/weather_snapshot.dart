/// Current and forecast weather conditions at a location.
class WeatherConditions {
  const WeatherConditions({
    required this.latitude,
    required this.longitude,
    required this.temperatureCelsius,
    required this.windSpeedKmh,
    required this.visibilityMeters,
    required this.rainProbabilityPercent,
    required this.uvIndex,
    required this.summary,
    required this.observedAt,
    this.windDirectionDegrees,
    this.humidityPercent,
  });

  final double latitude;
  final double longitude;
  final double temperatureCelsius;
  final double windSpeedKmh;
  final double visibilityMeters;
  final double rainProbabilityPercent;
  final double uvIndex;
  final String summary;
  final DateTime observedAt;
  final double? windDirectionDegrees;
  final double? humidityPercent;
}

/// Hourly forecast entry.
class WeatherForecastEntry {
  const WeatherForecastEntry({
    required this.time,
    required this.temperatureCelsius,
    required this.rainProbabilityPercent,
    required this.uvIndex,
    required this.windSpeedKmh,
    required this.summary,
  });

  final DateTime time;
  final double temperatureCelsius;
  final double rainProbabilityPercent;
  final double uvIndex;
  final double windSpeedKmh;
  final String summary;
}

/// Full weather snapshot including forecast.
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.current,
    required this.forecast,
  });

  final WeatherConditions current;
  final List<WeatherForecastEntry> forecast;
}
