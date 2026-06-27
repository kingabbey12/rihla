import 'dart:math' as math;

import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/navigation/data/services/navigation_session_helpers.dart';
import 'package:rihla/features/navigation/data/services/polyline_maneuver_engine.dart';
import 'package:rihla/features/navigation/data/services/polyline_route_deviation_detector.dart';
import 'package:rihla/features/navigation/domain/entities/lane_guidance.dart';
import 'package:rihla/features/navigation/domain/entities/maneuver_type.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_simulation.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'package:rihla/features/navigation/domain/entities/speed_limit.dart';
import 'package:rihla/features/navigation/domain/models/reroute_state.dart';
import 'package:rihla/features/navigation/domain/services/maneuver_engine.dart';
import 'package:rihla/features/navigation/domain/services/navigation_session_engine.dart';
import 'package:rihla/features/navigation/domain/services/route_deviation_detector.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';

/// Simulates turn-by-turn navigation along a route polyline.
class MockNavigationSessionEngine implements NavigationSessionEngine {
  MockNavigationSessionEngine({
    ManeuverEngine? maneuverEngine,
    RouteDeviationDetector? deviationDetector,
    NavigationSessionHelpers? helpers,
  })  : _maneuverEngine = maneuverEngine ?? PolylineManeuverEngine(),
        _deviationDetector = deviationDetector ?? PolylineRouteDeviationDetector(),
        _helpers = helpers ??
            NavigationSessionHelpers(maneuverEngine ?? PolylineManeuverEngine());

  final ManeuverEngine _maneuverEngine;
  final RouteDeviationDetector _deviationDetector;
  final NavigationSessionHelpers _helpers;

  static const _arrivalThresholdPercent = 98.0;

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
    final steps = _maneuverEngine.buildSteps(route);
    final start = coords.isNotEmpty
        ? coords.first
        : RouteCoordinate(
            latitude: journey.origin.latitude,
            longitude: journey.origin.longitude,
          );
    final maneuver = _helpers.buildManeuver(
      steps: steps,
      stepIndex: 0,
      distanceTraveledKm: 0,
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
      currentRoad: maneuver.currentRoad,
      currentManeuver: maneuver,
      maneuverSteps: steps,
      currentStepIndex: 0,
      distanceTraveledKm: 0,
      remainingDistanceKm: route.distanceKm,
      remainingDuration: Duration(seconds: route.durationSeconds),
      eta: now.add(Duration(seconds: route.durationSeconds)),
      speedKmh: 0,
      headingDegrees: _headingFor(coords, 0),
      routeProgressPercent: 0,
      laneGuidance: _helpers.laneGuidanceFor(maneuver.type),
      speedLimit: _helpers.speedLimitFor(maneuver.type),
      rerouteState: const RerouteIdle(),
      isOffRoute: false,
      simulation: const NavigationSimulation(),
      voiceEnabled: voiceEnabled,
      simulationMode: simulationMode,
      safety: SafetySnapshot.initial(),
      startedAt: now,
      lastUpdatedAt: now,
    );
  }

  @override
  NavigationSession advance({
    required NavigationSession session,
    required int tickCount,
    bool simulateOffRoute = false,
  }) {
    if (session.status == NavigationStatus.arrived) return session;
    if (session.simulation.playback == SimulationPlayback.paused) {
      return session.copyWith(lastUpdatedAt: DateTime.now());
    }

    final route = session.route;
    final coords = route.coordinates;
    final speedMultiplier = session.simulation.speedMultiplier;
    final progress = (tickCount * 0.06 * speedMultiplier).clamp(0.0, 1.0);
    final traveled = route.distanceKm * progress;
    final remaining = (route.distanceKm - traveled).clamp(0.0, route.distanceKm);
    final speed = (35.0 + (tickCount % 5) * 8.0) * speedMultiplier;
    final etaSeconds = speed > 0
        ? ((remaining / speed) * 3600).round()
        : route.durationSeconds;
    final now = DateTime.now();
    final progressPercent = route.distanceKm > 0
        ? (traveled / route.distanceKm * 100).clamp(0.0, 100.0)
        : 0.0;

    if (progressPercent >= _arrivalThresholdPercent) {
      return _arrivedSession(session, now);
    }

    final coordIndex = coords.length > 1
        ? ((coords.length - 1) * progress).floor().clamp(0, coords.length - 1)
        : 0;
    final position = coords.isNotEmpty
        ? coords[coordIndex]
        : RouteCoordinate(
            latitude: session.journey.origin.latitude,
            longitude: session.journey.origin.longitude,
          );

    var latitude = position.latitude;
    var longitude = position.longitude;
    if (simulateOffRoute) {
      latitude += 0.002;
      longitude += 0.002;
    }

    final currentPosition = LocationPosition(
      latitude: latitude,
      longitude: longitude,
      accuracy: 6 + (tickCount % 3),
      timestamp: now,
      speed: speed / 3.6,
      heading: _headingFor(coords, coordIndex),
    );

    final resolved = _helpers.resolveStep(
      steps: session.maneuverSteps,
      distanceTraveledKm: traveled,
    );
    final maneuver = _helpers.buildManeuver(
      steps: session.maneuverSteps,
      stepIndex: resolved.stepIndex,
      distanceTraveledKm: traveled,
    );

    final offRoute = simulateOffRoute ||
        _deviationDetector.isOffRoute(
          position: currentPosition,
          coordinates: coords,
        );

    return session.copyWith(
      currentPosition: currentPosition,
      currentRoad: maneuver.currentRoad,
      currentManeuver: maneuver,
      currentStepIndex: resolved.stepIndex,
      distanceTraveledKm: traveled,
      remainingDistanceKm: remaining,
      remainingDuration: Duration(seconds: etaSeconds),
      eta: now.add(Duration(seconds: etaSeconds)),
      speedKmh: speed,
      headingDegrees: _headingFor(coords, coordIndex),
      routeProgressPercent: progressPercent,
      laneGuidance: _helpers.laneGuidanceFor(maneuver.type),
      speedLimit: _helpers.speedLimitFor(maneuver.type),
      isOffRoute: offRoute,
      lastUpdatedAt: now,
    );
  }

  NavigationSession _arrivedSession(NavigationSession session, DateTime now) {
    final arriveManeuver = session.currentManeuver.copyWith(
      type: ManeuverType.arrive,
      instruction: _maneuverEngine.instructionFor(
        ManeuverType.arrive,
        session.journey.destination.name,
      ),
      distanceToManeuverKm: 0,
      nextRoad: session.journey.destination.name,
    );
    return session.copyWith(
      status: NavigationStatus.arrived,
      currentManeuver: arriveManeuver,
      remainingDistanceKm: 0,
      remainingDuration: Duration.zero,
      eta: now,
      speedKmh: 0,
      routeProgressPercent: 100,
      distanceTraveledKm: session.route.distanceKm,
      laneGuidance: LaneGuidance.empty,
      speedLimit: const SpeedLimit(limitKmh: 0, isPlaceholder: true),
      isOffRoute: false,
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
