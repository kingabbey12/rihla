import 'dart:math' as math;

import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_maneuver.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'package:rihla/features/navigation/domain/services/navigation_session_engine.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Simulates position and maneuver updates along a route polyline.
class MockNavigationSessionEngine implements NavigationSessionEngine {
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

  @override
  NavigationSession createInitial({
    required String sessionId,
    required JourneySummary journey,
    required RouteSummary route,
    bool simulationMode = true,
    bool voiceEnabled = false,
  }) {
    final now = DateTime.now();
    final coords = route.coordinates;
    final start = coords.isNotEmpty
        ? coords.first
        : RouteCoordinate(
            latitude: journey.origin.latitude,
            longitude: journey.origin.longitude,
          );

    return NavigationSession(
      sessionId: sessionId,
      journey: journey,
      route: route,
      status: NavigationStatus.navigating,
      currentPosition: LocationPosition(
        latitude: start.latitude,
        longitude: start.longitude,
        accuracy: 8,
        timestamp: now,
        speed: 0,
        heading: _headingFor(coords, 0),
      ),
      currentRoad: _roads.first,
      currentManeuver: NavigationManeuver(
        instruction: _maneuvers.last,
        distanceToManeuverKm: route.distanceKm * 0.25,
        isPlaceholder: true,
      ),
      remainingDistanceKm: route.distanceKm,
      remainingDuration: Duration(seconds: route.durationSeconds),
      eta: now.add(Duration(seconds: route.durationSeconds)),
      speedKmh: 0,
      headingDegrees: _headingFor(coords, 0),
      routeProgressPercent: 0,
      voiceEnabled: voiceEnabled,
      simulationMode: simulationMode,
      startedAt: now,
      lastUpdatedAt: now,
    );
  }

  @override
  NavigationSession advance({
    required NavigationSession session,
    required int tickCount,
  }) {
    final route = session.route;
    final coords = route.coordinates;
    final progress = (tickCount * 0.08).clamp(0.0, 0.95);
    final remaining = route.distanceKm * (1 - progress);
    final speed = 35.0 + (tickCount % 5) * 8.0;
    final etaSeconds = speed > 0
        ? ((remaining / speed) * 3600).round()
        : route.durationSeconds;
    final now = DateTime.now();
    final coordIndex = coords.length > 1
        ? ((coords.length - 1) * progress).floor().clamp(0, coords.length - 1)
        : 0;
    final position = coords.isNotEmpty
        ? coords[coordIndex]
        : RouteCoordinate(
            latitude: session.journey.origin.latitude,
            longitude: session.journey.origin.longitude,
          );

    return session.copyWith(
      currentPosition: LocationPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: 6 + (tickCount % 3),
        timestamp: now,
        speed: speed / 3.6,
        heading: _headingFor(coords, coordIndex),
      ),
      currentRoad: _roads[tickCount % _roads.length],
      currentManeuver: NavigationManeuver(
        instruction: _maneuvers[tickCount % _maneuvers.length],
        distanceToManeuverKm: (remaining * 0.25).clamp(0.1, remaining),
        isPlaceholder: true,
      ),
      remainingDistanceKm: remaining,
      remainingDuration: Duration(seconds: etaSeconds),
      eta: now.add(Duration(seconds: etaSeconds)),
      speedKmh: speed,
      headingDegrees: _headingFor(coords, coordIndex),
      routeProgressPercent: (progress * 100).clamp(0.0, 100.0),
      lastUpdatedAt: now,
    );
  }

  static double _headingFor(List<RouteCoordinate> coords, int index) {
    if (coords.length < 2) return 0;
    final from = coords[index.clamp(0, coords.length - 1)];
    final to = coords[(index + 1).clamp(0, coords.length - 1)];
    return _bearing(from.latitude, from.longitude, to.latitude, to.longitude);
  }

  static double _bearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dLambda = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(dLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }
}
