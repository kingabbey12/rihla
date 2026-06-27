import 'package:rihla/features/live_journey/domain/entities/journey_metric.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_source.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_status.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_update_method.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_metrics.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';

/// Non-navigation ambient metrics (scores, weather, fuel) for the dashboard.
class AmbientJourneyMetrics {
  const AmbientJourneyMetrics({
    required this.journeyScore,
    required this.safetyScore,
    required this.trafficScore,
    required this.weather,
    required this.roadCondition,
    required this.fuelEstimateLiters,
    required this.batteryEstimatePercent,
  });

  final JourneyMetric<double> journeyScore;
  final JourneyMetric<double> safetyScore;
  final JourneyMetric<double> trafficScore;
  final JourneyMetric<String> weather;
  final JourneyMetric<String> roadCondition;
  final JourneyMetric<double> fuelEstimateLiters;
  final JourneyMetric<double> batteryEstimatePercent;
}

/// Merges navigation session fields with ambient dashboard metrics.
class LiveJourneySessionMetricsMapper {
  const LiveJourneySessionMetricsMapper();

  LiveJourneyMetrics compose({
    required NavigationSession session,
    required AmbientJourneyMetrics ambient,
  }) {
    final timestamp = session.lastUpdatedAt;
    final source = session.simulationMode ? MetricSource.mock : MetricSource.gps;
    const updateMethod = MetricUpdateMethod.stream;

    JourneyMetric<T> fromSession<T>(T value, {MetricStatus status = MetricStatus.good}) {
      return JourneyMetric<T>(
        value: value,
        status: status,
        timestamp: timestamp,
        source: source,
        updateMethod: updateMethod,
      );
    }

    final speedStatus =
        session.speedKmh > 100 ? MetricStatus.warning : MetricStatus.good;
    final safetyScore = session.safety.assessment.overallSafetyScore;
    final safetyStatus = safetyScore >= 75
        ? MetricStatus.good
        : safetyScore >= 50
            ? MetricStatus.warning
            : MetricStatus.critical;

    return LiveJourneyMetrics(
      journeyScore: ambient.journeyScore,
      safetyScore: fromSession(safetyScore, status: safetyStatus),
      trafficScore: ambient.trafficScore,
      weather: ambient.weather,
      roadCondition: ambient.roadCondition,
      currentSpeedKmh: fromSession(session.speedKmh, status: speedStatus),
      eta: fromSession(session.remainingDuration),
      remainingDistanceKm: fromSession(session.remainingDistanceKm),
      fuelEstimateLiters: ambient.fuelEstimateLiters,
      batteryEstimatePercent: ambient.batteryEstimatePercent,
      currentRoadName: fromSession(session.currentRoad),
      nextManeuver: fromSession(session.currentManeuver.instruction),
      arrivalTime: fromSession(session.eta),
    );
  }
}
