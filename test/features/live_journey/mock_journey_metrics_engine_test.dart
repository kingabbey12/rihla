import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/live_journey/data/services/mock_journey_metrics_engine.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_source.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_update_method.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

void main() {
  late MockJourneyMetricsEngine engine;
  late RouteSummary route;

  setUp(() {
    engine = MockJourneyMetricsEngine();
    route = const RouteSummary(
      id: 'mock_safe',
      profile: RouteProfile.safe,
      distanceKm: 12.0,
      durationSeconds: 960,
      coordinates: [
        RouteCoordinate(latitude: 24.71, longitude: 46.67),
        RouteCoordinate(latitude: 24.72, longitude: 46.68),
      ],
      journeyScore: 82,
      fuelEstimateLiters: 0.9,
      trafficSummary: 'Light',
      safetySummary: 'High safety rating',
    );
  });

  test('initialMetrics seeds all required fields from route', () {
    final metrics = engine.initialMetrics(route);

    expect(metrics.journeyScore.value, route.journeyScore);
    expect(metrics.remainingDistanceKm.value, route.distanceKm);
    expect(metrics.fuelEstimateLiters.value, route.fuelEstimateLiters);
    expect(metrics.journeyScore.source, MetricSource.mock);
    expect(metrics.journeyScore.updateMethod, MetricUpdateMethod.timer);
    expect(metrics.nextManeuver.value, contains('coming soon'));
  });

  test('tick reduces remaining distance and updates speed', () {
    final initial = engine.initialMetrics(route);
    final updated = engine.tick(
      current: initial,
      route: route,
      tickCount: 3,
    );

    expect(
      updated.remainingDistanceKm.value,
      lessThan(initial.remainingDistanceKm.value),
    );
    expect(updated.currentSpeedKmh.value, greaterThan(0));
    expect(updated.currentRoadName.value, isNotEmpty);
  });

  test('ambientMetrics returns supplementary dashboard fields', () {
    final ambient = engine.ambientMetrics(
      route: route,
      tickCount: 2,
      progressPercent: 20,
    );

    expect(ambient.journeyScore.value, greaterThan(0));
    expect(ambient.weather.value, isNotEmpty);
    expect(ambient.fuelEstimateLiters.value, lessThan(route.fuelEstimateLiters));
  });
}
