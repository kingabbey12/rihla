import 'package:rihla/features/live_journey/domain/models/live_journey_metrics.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Contract for producing live journey metric snapshots.
abstract class JourneyMetricsEngine {
  LiveJourneyMetrics initialMetrics(RouteSummary route);

  LiveJourneyMetrics tick({
    required LiveJourneyMetrics current,
    required RouteSummary route,
    required int tickCount,
  });
}
