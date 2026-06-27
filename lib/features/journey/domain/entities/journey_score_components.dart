/// Independent score inputs used to compute the overall journey score.
///
/// Each component is 0–100 where higher is better. The [JourneyScoreEngine]
/// combines them with configurable weights so AI can replace individual
/// values later without changing the calculation contract.
class JourneyScoreComponents {
  const JourneyScoreComponents({
    required this.safety,
    required this.traffic,
    required this.weather,
    required this.roadConditions,
    required this.fuelEfficiency,
    required this.vehicleStatus,
  });

  final double safety;
  final double traffic;
  final double weather;
  final double roadConditions;
  final double fuelEfficiency;
  final double vehicleStatus;

  /// Default weights — must sum to 1.0.
  static const Map<String, double> defaultWeights = {
    'safety': 0.25,
    'traffic': 0.20,
    'weather': 0.15,
    'roadConditions': 0.15,
    'fuelEfficiency': 0.15,
    'vehicleStatus': 0.10,
  };
}
