import 'package:rihla/features/live_journey/domain/entities/journey_metric.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_source.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_status.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_update_method.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_metrics.dart';
import 'package:rihla/features/live_journey/domain/services/journey_metrics_engine.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Mock engine that simulates live metric drift every few seconds.
class MockJourneyMetricsEngine implements JourneyMetricsEngine {
  static const _roads = [
    'King Fahd Road',
    'Northern Ring Road',
    'Olaya Street',
    'Eastern Ring Road',
    'Airport Road',
  ];

  static const _maneuvers = [
    'Continue straight',
    'Turn right onto Olaya St',
    'Keep left at the fork',
    'Merge onto Ring Road',
    'Navigation instructions coming soon',
  ];

  JourneyMetric<T> _metric<T>(T value, MetricStatus status) => JourneyMetric<T>(
        value: value,
        status: status,
        timestamp: DateTime.now(),
        source: MetricSource.mock,
        updateMethod: MetricUpdateMethod.timer,
      );

  MetricStatus _scoreStatus(double score) {
    if (score >= 75) return MetricStatus.good;
    if (score >= 50) return MetricStatus.warning;
    return MetricStatus.critical;
  }

  @override
  LiveJourneyMetrics initialMetrics(RouteSummary route) {
    final now = DateTime.now();
    final arrival = now.add(Duration(seconds: route.durationSeconds));
    return LiveJourneyMetrics(
      journeyScore: _metric(route.journeyScore, _scoreStatus(route.journeyScore)),
      safetyScore: _metric(
        route.journeyScore * 0.95,
        _scoreStatus(route.journeyScore * 0.95),
      ),
      trafficScore: _metric(72, MetricStatus.good),
      weather: _metric('Clear skies · 32°C', MetricStatus.good),
      roadCondition: _metric('Good', MetricStatus.good),
      currentSpeedKmh: _metric(0, MetricStatus.good),
      eta: _metric(
        Duration(seconds: route.durationSeconds),
        MetricStatus.good,
      ),
      remainingDistanceKm: _metric(route.distanceKm, MetricStatus.good),
      fuelEstimateLiters: _metric(
        route.fuelEstimateLiters,
        MetricStatus.good,
      ),
      batteryEstimatePercent: _metric(
        route.distanceKm * 1.2,
        MetricStatus.good,
      ),
      currentRoadName: _metric(_roads.first, MetricStatus.good),
      nextManeuver: _metric(_maneuvers.last, MetricStatus.good),
      arrivalTime: _metric(arrival, MetricStatus.good),
    );
  }

  @override
  LiveJourneyMetrics tick({
    required LiveJourneyMetrics current,
    required RouteSummary route,
    required int tickCount,
  }) {
    final progress = (tickCount * 0.08).clamp(0.0, 0.95);
    final remaining = route.distanceKm * (1 - progress);
    final speed = 35.0 + (tickCount % 5) * 8.0;
    final etaSeconds = speed > 0
        ? ((remaining / speed) * 3600).round()
        : route.durationSeconds;
    final arrival = DateTime.now().add(Duration(seconds: etaSeconds));

    final journeyScore =
        (route.journeyScore - tickCount * 0.3).clamp(40.0, 100.0).toDouble();
    final safetyScore =
        (journeyScore * 0.97).clamp(40.0, 100.0).toDouble();
    final trafficScore =
        (72.0 - tickCount * 2).clamp(30.0, 95.0).toDouble();
    final fuelLeft = route.fuelEstimateLiters * (1 - progress);
    final batteryLeft =
        (route.distanceKm * 1.2 * (1 - progress)).clamp(0.0, 100.0).toDouble();

    return LiveJourneyMetrics(
      journeyScore: _metric(journeyScore, _scoreStatus(journeyScore)),
      safetyScore: _metric(safetyScore, _scoreStatus(safetyScore)),
      trafficScore: _metric(trafficScore, _scoreStatus(trafficScore)),
      weather: _metric(
        tickCount.isEven ? 'Clear skies · 32°C' : 'Partly cloudy · 31°C',
        MetricStatus.good,
      ),
      roadCondition: _metric(
        remaining < route.distanceKm * 0.2 ? 'Fair' : 'Good',
        remaining < route.distanceKm * 0.15
            ? MetricStatus.warning
            : MetricStatus.good,
      ),
      currentSpeedKmh: _metric(
        speed,
        speed > 100 ? MetricStatus.warning : MetricStatus.good,
      ),
      eta: _metric(Duration(seconds: etaSeconds), MetricStatus.good),
      remainingDistanceKm: _metric(remaining, MetricStatus.good),
      fuelEstimateLiters: _metric(
        fuelLeft,
        fuelLeft < 2 ? MetricStatus.warning : MetricStatus.good,
      ),
      batteryEstimatePercent: _metric(
        batteryLeft,
        batteryLeft < 15 ? MetricStatus.warning : MetricStatus.good,
      ),
      currentRoadName: _metric(_roads[tickCount % _roads.length], MetricStatus.good),
      nextManeuver: _metric(_maneuvers[tickCount % _maneuvers.length], MetricStatus.good),
      arrivalTime: _metric(arrival, MetricStatus.good),
    );
  }
}
