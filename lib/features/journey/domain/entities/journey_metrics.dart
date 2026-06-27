/// Traffic congestion level for a journey.
enum TrafficLevel {
  light,
  moderate,
  heavy,
}

/// Road surface / condition summary.
enum RoadConditionLevel {
  excellent,
  good,
  fair,
  poor,
}

/// Mock journey metrics — will be replaced by live routing data later.
class JourneyMetrics {
  const JourneyMetrics({
    required this.distanceKm,
    required this.durationMinutes,
    required this.weatherSummary,
    required this.temperatureCelsius,
    required this.trafficLevel,
    required this.fuelEstimateLiters,
    required this.batteryEstimatePercent,
    required this.roadCondition,
    required this.departureSuggestions,
  });

  final double distanceKm;
  final int durationMinutes;
  final String weatherSummary;
  final double temperatureCelsius;
  final TrafficLevel trafficLevel;
  final double fuelEstimateLiters;

  /// Estimated battery consumption for EVs (0–100 % of charge).
  final double batteryEstimatePercent;
  final RoadConditionLevel roadCondition;
  final List<String> departureSuggestions;
}
