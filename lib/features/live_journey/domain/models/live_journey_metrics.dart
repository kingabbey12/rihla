import 'package:rihla/features/live_journey/domain/entities/journey_metric.dart';

/// Snapshot of all live journey metrics at a point in time.
class LiveJourneyMetrics {
  const LiveJourneyMetrics({
    required this.journeyScore,
    required this.safetyScore,
    required this.trafficScore,
    required this.weather,
    required this.roadCondition,
    required this.currentSpeedKmh,
    required this.eta,
    required this.remainingDistanceKm,
    required this.fuelEstimateLiters,
    required this.batteryEstimatePercent,
    required this.currentRoadName,
    required this.nextManeuver,
    required this.arrivalTime,
  });

  final JourneyMetric<double> journeyScore;
  final JourneyMetric<double> safetyScore;
  final JourneyMetric<double> trafficScore;
  final JourneyMetric<String> weather;
  final JourneyMetric<String> roadCondition;
  final JourneyMetric<double> currentSpeedKmh;
  final JourneyMetric<Duration> eta;
  final JourneyMetric<double> remainingDistanceKm;
  final JourneyMetric<double> fuelEstimateLiters;
  final JourneyMetric<double> batteryEstimatePercent;
  final JourneyMetric<String> currentRoadName;
  final JourneyMetric<String> nextManeuver;
  final JourneyMetric<DateTime> arrivalTime;
}
