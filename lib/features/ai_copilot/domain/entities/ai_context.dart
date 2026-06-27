import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_metrics.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';

/// Structured context bundle fed to the prompt builder.
///
/// The AI consumes this data — it never replaces routing or safety engines.
class AiContext {
  const AiContext({
    required this.mode,
    this.journey,
    this.route,
    this.session,
    this.safety,
    this.location,
    this.liveMetrics,
    this.averageSpeedKmh,
    this.driverScore,
    this.safetyScoreTrend,
  });

  final AiCopilotMode mode;
  final JourneySummary? journey;
  final RouteSummary? route;
  final NavigationSession? session;
  final SafetySnapshot? safety;
  final LocationPosition? location;
  final LiveJourneyMetrics? liveMetrics;
  final double? averageSpeedKmh;
  final double? driverScore;
  final String? safetyScoreTrend;
}
