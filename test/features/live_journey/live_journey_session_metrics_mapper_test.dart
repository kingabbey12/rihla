import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/live_journey/data/mappers/live_journey_session_metrics_mapper.dart';
import 'package:rihla/features/live_journey/data/services/mock_journey_metrics_engine.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_source.dart';
import 'package:rihla/features/navigation/data/services/mock_navigation_session_engine.dart';

import '../navigation/navigation_test_helpers.dart';

void main() {
  test('compose maps navigation session fields to live metrics', () {
    final engine = MockNavigationSessionEngine();
    final metricsEngine = MockJourneyMetricsEngine();
    const mapper = LiveJourneySessionMetricsMapper();

    final session = engine.createInitial(
      sessionId: 'nav_1',
      journey: sampleJourneySummary(),
      route: sampleRouteSummary(),
    );
    final ambient = metricsEngine.ambientMetrics(
      route: session.route,
      tickCount: 1,
      progressPercent: session.routeProgressPercent,
    );
    final metrics = mapper.compose(session: session, ambient: ambient);

    expect(metrics.currentRoadName.value, session.currentRoad);
    expect(metrics.remainingDistanceKm.value, session.remainingDistanceKm);
    expect(metrics.nextManeuver.value, session.currentManeuver.instruction);
    expect(metrics.currentSpeedKmh.source, MetricSource.mock);
    expect(metrics.journeyScore.value, greaterThan(0));
  });
}
