/// UAE-specific weather alert.
enum UaeWeatherAlertType {
  fog,
  sandstorm,
  heavyRain,
  floodProne,
  extremeHeat,
}

class UaeWeatherAlert {
  const UaeWeatherAlert({
    required this.type,
    required this.title,
    required this.guidance,
    required this.severity,
  });

  final UaeWeatherAlertType type;
  final String title;
  final String guidance;
  final int severity;
}
