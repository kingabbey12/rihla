import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Contract for advancing a navigation session along a route.
abstract class NavigationSessionEngine {
  NavigationSession createInitial({
    required String sessionId,
    required JourneySummary journey,
    required RouteSummary route,
    bool simulationMode,
    bool voiceEnabled,
  });

  NavigationSession advance({
    required NavigationSession session,
    required int tickCount,
    LocationPosition? gpsFix,
    bool simulateOffRoute = false,
  });
}
