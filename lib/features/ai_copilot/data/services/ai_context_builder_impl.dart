import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/services/ai_context_builder.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_metrics.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Builds structured [AiContext] from domain entities.
class AiContextBuilderImpl implements AiContextBuilder {
  @override
  AiContext buildJourneyAdvisor({
    required JourneySummary journey,
    RouteSummary? route,
    LocationPosition? location,
  }) {
    return AiContext(
      mode: AiCopilotMode.journeyAdvisor,
      journey: journey,
      route: route,
      location: location,
    );
  }

  @override
  AiContext buildDrivingCopilot({
    required NavigationSession session,
    LiveJourneyMetrics? liveMetrics,
    LocationPosition? location,
  }) {
    return AiContext(
      mode: AiCopilotMode.drivingCopilot,
      journey: session.journey,
      route: session.route,
      session: session,
      safety: session.safety,
      location: location ?? session.currentPosition,
      liveMetrics: liveMetrics,
    );
  }

  @override
  AiContext buildJourneyReview({
    required NavigationSession session,
    LiveJourneyMetrics? liveMetrics,
    required double averageSpeedKmh,
    required double driverScore,
    required String safetyScoreTrend,
  }) {
    return AiContext(
      mode: AiCopilotMode.journeyReview,
      journey: session.journey,
      route: session.route,
      session: session,
      safety: session.safety,
      location: session.currentPosition,
      liveMetrics: liveMetrics,
      averageSpeedKmh: averageSpeedKmh,
      driverScore: driverScore,
      safetyScoreTrend: safetyScoreTrend,
    );
  }
}
