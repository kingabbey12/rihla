import 'package:rihla/features/live_journey/data/mappers/live_journey_session_metrics_mapper.dart';
import 'package:rihla/features/live_journey/domain/entities/journey_metric.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_source.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_status.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_update_method.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_metrics.dart';
import 'package:rihla/features/live_journey/domain/services/journey_metrics_engine.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';
import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';

/// Production metrics engine using live weather and traffic context.
class LiveJourneyMetricsEngine implements JourneyMetricsEngine {
  LiveJourneyMetricsEngine({
    WeatherSnapshot? weather,
    TrafficSnapshot? traffic,
  })  : _weather = weather,
        _traffic = traffic;

  WeatherSnapshot? _weather;
  TrafficSnapshot? _traffic;

  void updateWeather(WeatherSnapshot? weather) => _weather = weather;
  void updateTraffic(TrafficSnapshot? traffic) => _traffic = traffic;

  JourneyMetric<T> _metric<T>(
    T value,
    MetricStatus status, {
    MetricSource source = MetricSource.calculated,
  }) =>
      JourneyMetric<T>(
        value: value,
        status: status,
        timestamp: DateTime.now(),
        source: source,
        updateMethod: MetricUpdateMethod.timer,
      );

  MetricStatus _scoreStatus(double score) {
    if (score >= 75) return MetricStatus.good;
    if (score >= 50) return MetricStatus.warning;
    return MetricStatus.critical;
  }

  String _weatherLabel() {
    final w = _weather?.current;
    if (w == null) return 'Weather unavailable';
    return '${w.summary} · ${w.temperatureCelsius.round()}°C';
  }

  double _trafficScore(int tickCount) {
    final t = _traffic;
    if (t?.trafficScore != null) return t!.trafficScore!;
    return (72.0 - tickCount * 2).clamp(30.0, 95.0);
  }

  @override
  LiveJourneyMetrics initialMetrics(RouteSummary route) {
    final now = DateTime.now();
    final delay = _traffic?.etaDelayMinutes ?? 0;
    final arrival = now.add(
      Duration(seconds: route.durationSeconds + delay * 60),
    );
    final trafficScore = _trafficScore(0);

    return LiveJourneyMetrics(
      journeyScore: _metric(route.journeyScore, _scoreStatus(route.journeyScore)),
      safetyScore: _metric(
        route.journeyScore * 0.95,
        _scoreStatus(route.journeyScore * 0.95),
      ),
      trafficScore: _metric(trafficScore, _scoreStatus(trafficScore)),
      weather: _metric(_weatherLabel(), MetricStatus.good),
      roadCondition: _metric('Good', MetricStatus.good),
      currentSpeedKmh: _metric(0, MetricStatus.good),
      eta: _metric(
        Duration(seconds: route.durationSeconds + delay * 60),
        MetricStatus.good,
      ),
      remainingDistanceKm: _metric(route.distanceKm, MetricStatus.good),
      fuelEstimateLiters: _metric(route.fuelEstimateLiters, MetricStatus.good),
      batteryEstimatePercent: _metric(
        route.distanceKm * 1.2,
        MetricStatus.good,
      ),
      currentRoadName: _metric(route.trafficSummary, MetricStatus.good),
      nextManeuver: _metric('Navigation instructions coming soon', MetricStatus.good),
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
    final speed = _traffic?.averageSpeedKmh ??
        (35.0 + (tickCount % 5) * 8.0);
    final delay = _traffic?.etaDelayMinutes ?? 0;
    final etaSeconds = speed > 0
        ? ((remaining / speed) * 3600).round() + delay * 60
        : route.durationSeconds;
    final arrival = DateTime.now().add(Duration(seconds: etaSeconds));

    final journeyScore =
        (route.journeyScore - tickCount * 0.3).clamp(40.0, 100.0).toDouble();
    final safetyScore =
        (journeyScore * 0.97).clamp(40.0, 100.0).toDouble();
    final trafficScore = _trafficScore(tickCount);
    final fuelLeft = route.fuelEstimateLiters * (1 - progress);
    final batteryLeft =
        (route.distanceKm * 1.2 * (1 - progress)).clamp(0.0, 100.0).toDouble();

    return LiveJourneyMetrics(
      journeyScore: _metric(journeyScore, _scoreStatus(journeyScore)),
      safetyScore: _metric(safetyScore, _scoreStatus(safetyScore)),
      trafficScore: _metric(trafficScore, _scoreStatus(trafficScore)),
      weather: _metric(_weatherLabel(), MetricStatus.good),
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
      currentRoadName: _metric(route.trafficSummary, MetricStatus.good),
      nextManeuver: _metric('Continue on route', MetricStatus.good),
      arrivalTime: _metric(arrival, MetricStatus.good),
    );
  }

  @override
  AmbientJourneyMetrics ambientMetrics({
    required RouteSummary route,
    required int tickCount,
    required double progressPercent,
  }) {
    final progress = (progressPercent / 100).clamp(0.0, 1.0);
    final journeyScore =
        (route.journeyScore - tickCount * 0.3).clamp(40.0, 100.0).toDouble();
    final safetyScore =
        (journeyScore * 0.97).clamp(40.0, 100.0).toDouble();
    final trafficScore = _trafficScore(tickCount);
    final fuelLeft = route.fuelEstimateLiters * (1 - progress);
    final batteryLeft =
        (route.distanceKm * 1.2 * (1 - progress)).clamp(0.0, 100.0).toDouble();
    final remaining = route.distanceKm * (1 - progress);

    return AmbientJourneyMetrics(
      journeyScore: _metric(journeyScore, _scoreStatus(journeyScore)),
      safetyScore: _metric(safetyScore, _scoreStatus(safetyScore)),
      trafficScore: _metric(trafficScore, _scoreStatus(trafficScore)),
      weather: _metric(_weatherLabel(), MetricStatus.good),
      roadCondition: _metric(
        remaining < route.distanceKm * 0.2 ? 'Fair' : 'Good',
        remaining < route.distanceKm * 0.15
            ? MetricStatus.warning
            : MetricStatus.good,
      ),
      fuelEstimateLiters: _metric(
        fuelLeft,
        fuelLeft < 2 ? MetricStatus.warning : MetricStatus.good,
      ),
      batteryEstimatePercent: _metric(
        batteryLeft,
        batteryLeft < 15 ? MetricStatus.warning : MetricStatus.good,
      ),
    );
  }
}
