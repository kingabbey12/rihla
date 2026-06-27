import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_metrics.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Assembles [AiContext] from structured app data.
abstract class AiContextBuilder {
  AiContext buildJourneyAdvisor({
    required JourneySummary journey,
    RouteSummary? route,
    LocationPosition? location,
  });

  AiContext buildDrivingCopilot({
    required NavigationSession session,
    LiveJourneyMetrics? liveMetrics,
    LocationPosition? location,
  });

  AiContext buildJourneyReview({
    required NavigationSession session,
    LiveJourneyMetrics? liveMetrics,
    required double averageSpeedKmh,
    required double driverScore,
    required String safetyScoreTrend,
  });
}
