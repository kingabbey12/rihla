import 'package:rihla/features/live_journey/data/mappers/live_journey_session_metrics_mapper.dart';
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

  /// Ambient dashboard metrics not sourced from the navigation session.
  AmbientJourneyMetrics ambientMetrics({
    required RouteSummary route,
    required int tickCount,
    required double progressPercent,
  });
}
