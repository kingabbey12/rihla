import 'dart:math' as math;

import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/navigation/data/services/mock_navigation_session_engine.dart';
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

/// Production navigation engine driven by the device GPS fix.
///
/// When [advance] receives a [gpsFix], progress, maneuvers, and ETA are derived
/// from the real position along the route polyline. Simulation ticks are only
/// used when [NavigationSession.simulationMode] is true (debug builds).
class GpsNavigationSessionEngine implements NavigationSessionEngine {
  GpsNavigationSessionEngine({
    ManeuverEngine? maneuverEngine,
    RouteDeviationDetector? deviationDetector,
    NavigationSessionHelpers? helpers,
    MockNavigationSessionEngine? simulationEngine,
  })  : _maneuverEngine = maneuverEngine ?? PolylineManeuverEngine(),
        _deviationDetector = deviationDetector ?? PolylineRouteDeviationDetector(),
        _helpers = helpers ??
            NavigationSessionHelpers(maneuverEngine ?? PolylineManeuverEngine()),
        _simulationEngine = simulationEngine ??
            MockNavigationSessionEngine(
              maneuverEngine: maneuverEngine,
              deviationDetector: deviationDetector,
              helpers: helpers,
            );

  final ManeuverEngine _maneuverEngine;
  final RouteDeviationDetector _deviationDetector;
  final NavigationSessionHelpers _helpers;
  final MockNavigationSessionEngine _simulationEngine;

  static const _arrivalThresholdMeters = 40.0;

  @override
  NavigationSession createInitial({
    required String sessionId,
    required JourneySummary journey,
    required RouteSummary route,
    bool simulationMode = false,
    bool voiceEnabled = false,
  }) {
    return _simulationEngine.createInitial(
      sessionId: sessionId,
      journey: journey,
      route: route,
      simulationMode: simulationMode,
      voiceEnabled: voiceEnabled,
    ).copyWith(simulationMode: simulationMode);
  }

  @override
  NavigationSession advance({
    required NavigationSession session,
    required int tickCount,
    LocationPosition? gpsFix,
    bool simulateOffRoute = false,
  }) {
    if (session.simulationMode || gpsFix == null) {
      return _simulationEngine.advance(
        session: session,
        tickCount: tickCount,
        gpsFix: gpsFix,
        simulateOffRoute: simulateOffRoute,
      );
    }
    return _advanceWithGps(
      session: session,
      gpsFix: gpsFix,
      simulateOffRoute: simulateOffRoute,
    );
  }

  NavigationSession _advanceWithGps({
    required NavigationSession session,
    required LocationPosition gpsFix,
    required bool simulateOffRoute,
  }) {
    if (session.status == NavigationStatus.arrived) return session;
    if (session.simulation.playback == SimulationPlayback.paused) {
      return session.copyWith(lastUpdatedAt: DateTime.now());
    }

    final route = session.route;
    final coords = route.coordinates;
    if (coords.isEmpty) return session;

    final now = DateTime.now();
    // Project the raw GPS fix onto the route polyline. We use the snapped point
    // for the vehicle marker (snap-to-road) so it never floats off a valid
    // nearby road, while keeping the raw fix for off-route detection.
    final snap = _snapToRoute(coords, gpsFix.latitude, gpsFix.longitude);
    final traveledKm = snap.alongKm;
    final snappedFix = LocationPosition(
      latitude: snap.lat,
      longitude: snap.lng,
      accuracy: gpsFix.accuracy,
      timestamp: gpsFix.timestamp,
      altitude: gpsFix.altitude,
      speed: gpsFix.speed,
      heading: gpsFix.heading,
    );
    final remainingKm =
        (route.distanceKm - traveledKm).clamp(0.0, route.distanceKm);
    final speedKmh = gpsFix.speed != null && gpsFix.speed! > 0
        ? gpsFix.speed! * 3.6
        : session.speedKmh;
    final etaSeconds = speedKmh > 1
        ? ((remainingKm / speedKmh) * 3600).round()
        : session.remainingDuration.inSeconds;
    final progressPercent = route.distanceKm > 0
        ? (traveledKm / route.distanceKm * 100).clamp(0.0, 100.0)
        : 0.0;

    if (remainingKm * 1000 <= _arrivalThresholdMeters) {
      return _arrivedSession(session, snappedFix, now);
    }

    // Off-route detection uses the RAW fix so genuine deviations are detected;
    // the marker uses the snapped position only while on-route.
    final offRoute = simulateOffRoute ||
        _deviationDetector.isOffRoute(
          position: gpsFix,
          coordinates: coords,
        );
    final markerFix = offRoute ? gpsFix : snappedFix;

    final resolved = _helpers.resolveStep(
      steps: session.maneuverSteps,
      distanceTraveledKm: traveledKm,
    );
    final maneuver = _helpers.buildManeuver(
      steps: session.maneuverSteps,
      stepIndex: resolved.stepIndex,
      distanceTraveledKm: traveledKm,
    );

    return session.copyWith(
      currentPosition: markerFix,
      currentRoad: maneuver.currentRoad,
      currentManeuver: maneuver,
      currentStepIndex: resolved.stepIndex,
      distanceTraveledKm: traveledKm,
      remainingDistanceKm: remainingKm,
      remainingDuration: Duration(seconds: etaSeconds),
      eta: now.add(Duration(seconds: etaSeconds)),
      speedKmh: speedKmh,
      headingDegrees: gpsFix.heading ?? session.headingDegrees,
      routeProgressPercent: progressPercent,
      laneGuidance: _helpers.laneGuidanceFor(maneuver.type),
      speedLimit: _helpers.speedLimitFor(maneuver.type),
      isOffRoute: offRoute,
      lastUpdatedAt: now,
    );
  }

  NavigationSession _arrivedSession(
    NavigationSession session,
    LocationPosition gpsFix,
    DateTime now,
  ) {
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
      currentPosition: gpsFix,
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
      rerouteState: const RerouteIdle(),
      lastUpdatedAt: now,
    );
  }

  /// Projects [lat]/[lng] onto the route polyline, returning the snapped
  /// coordinate, the cumulative distance travelled to that point, and the
  /// lateral distance from the road.
  static ({double lat, double lng, double alongKm, double lateralKm})
      _snapToRoute(
    List<RouteCoordinate> coords,
    double lat,
    double lng,
  ) {
    if (coords.length < 2) {
      return (lat: lat, lng: lng, alongKm: 0, lateralKm: 0);
    }

    var bestDistKm = double.infinity;
    var bestAlongKm = 0.0;
    var bestLat = coords.first.latitude;
    var bestLng = coords.first.longitude;
    var cumulativeKm = 0.0;

    for (var i = 0; i < coords.length - 1; i++) {
      final a = coords[i];
      final b = coords[i + 1];
      final segKm = _haversineKm(a.latitude, a.longitude, b.latitude, b.longitude);
      final proj = _closestPointOnSegment(
        lat,
        lng,
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
      if (proj.distKm < bestDistKm) {
        bestDistKm = proj.distKm;
        bestAlongKm = cumulativeKm + segKm * proj.t;
        bestLat = proj.lat;
        bestLng = proj.lng;
      }
      cumulativeKm += segKm;
    }
    return (
      lat: bestLat,
      lng: bestLng,
      alongKm: bestAlongKm.clamp(0.0, cumulativeKm),
      lateralKm: bestDistKm,
    );
  }

  /// Returns the projected point on a segment: parametric t ∈ [0,1], the
  /// snapped lat/lng, and the perpendicular distance in km.
  static ({double t, double lat, double lng, double distKm})
      _closestPointOnSegment(
    double lat,
    double lng,
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dx = lat2 - lat1;
    final dy = lng2 - lng1;
    if (dx == 0 && dy == 0) {
      return (t: 0, lat: lat1, lng: lng1, distKm: _haversineKm(lat, lng, lat1, lng1));
    }
    final t = ((lat - lat1) * dx + (lng - lng1) * dy) / (dx * dx + dy * dy);
    final clamped = t.clamp(0.0, 1.0);
    final projLat = lat1 + clamped * dx;
    final projLng = lng1 + clamped * dy;
    return (
      t: clamped,
      lat: projLat,
      lng: projLng,
      distKm: _haversineKm(lat, lng, projLat, projLng),
    );
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
