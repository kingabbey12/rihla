import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/navigation/domain/entities/lane_guidance.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_maneuver.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_simulation.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'package:rihla/features/navigation/domain/entities/route_maneuver_step.dart';
import 'package:rihla/features/navigation/domain/entities/speed_limit.dart';
import 'package:rihla/features/navigation/domain/models/reroute_state.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';

/// Central representation of one active navigation session.
///
/// Future capabilities extend this model — they do not replace it.
class NavigationSession {
  const NavigationSession({
    required this.sessionId,
    required this.journey,
    required this.route,
    required this.status,
    required this.currentPosition,
    required this.currentRoad,
    required this.currentManeuver,
    required this.maneuverSteps,
    required this.currentStepIndex,
    required this.distanceTraveledKm,
    required this.remainingDistanceKm,
    required this.remainingDuration,
    required this.eta,
    required this.speedKmh,
    required this.headingDegrees,
    required this.routeProgressPercent,
    required this.laneGuidance,
    required this.speedLimit,
    required this.rerouteState,
    required this.isOffRoute,
    required this.simulation,
    required this.voiceEnabled,
    required this.simulationMode,
    required this.safety,
    required this.startedAt,
    required this.lastUpdatedAt,
  });

  final String sessionId;
  final JourneySummary journey;
  final RouteSummary route;
  final NavigationStatus status;
  final LocationPosition currentPosition;
  final String currentRoad;
  final NavigationManeuver currentManeuver;
  final List<RouteManeuverStep> maneuverSteps;
  final int currentStepIndex;
  final double distanceTraveledKm;
  final double remainingDistanceKm;
  final Duration remainingDuration;
  final DateTime eta;
  final double speedKmh;
  final double headingDegrees;
  final double routeProgressPercent;
  final LaneGuidance laneGuidance;
  final SpeedLimit speedLimit;
  final RerouteState rerouteState;
  final bool isOffRoute;
  final NavigationSimulation simulation;
  final bool voiceEnabled;
  final bool simulationMode;
  final SafetySnapshot safety;
  final DateTime startedAt;
  final DateTime lastUpdatedAt;

  bool get hasArrived => status == NavigationStatus.arrived;

  NavigationSession copyWith({
    String? sessionId,
    JourneySummary? journey,
    RouteSummary? route,
    NavigationStatus? status,
    LocationPosition? currentPosition,
    String? currentRoad,
    NavigationManeuver? currentManeuver,
    List<RouteManeuverStep>? maneuverSteps,
    int? currentStepIndex,
    double? distanceTraveledKm,
    double? remainingDistanceKm,
    Duration? remainingDuration,
    DateTime? eta,
    double? speedKmh,
    double? headingDegrees,
    double? routeProgressPercent,
    LaneGuidance? laneGuidance,
    SpeedLimit? speedLimit,
    RerouteState? rerouteState,
    bool? isOffRoute,
    NavigationSimulation? simulation,
    bool? voiceEnabled,
    bool? simulationMode,
    SafetySnapshot? safety,
    DateTime? startedAt,
    DateTime? lastUpdatedAt,
  }) {
    return NavigationSession(
      sessionId: sessionId ?? this.sessionId,
      journey: journey ?? this.journey,
      route: route ?? this.route,
      status: status ?? this.status,
      currentPosition: currentPosition ?? this.currentPosition,
      currentRoad: currentRoad ?? this.currentRoad,
      currentManeuver: currentManeuver ?? this.currentManeuver,
      maneuverSteps: maneuverSteps ?? this.maneuverSteps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      distanceTraveledKm: distanceTraveledKm ?? this.distanceTraveledKm,
      remainingDistanceKm: remainingDistanceKm ?? this.remainingDistanceKm,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      eta: eta ?? this.eta,
      speedKmh: speedKmh ?? this.speedKmh,
      headingDegrees: headingDegrees ?? this.headingDegrees,
      routeProgressPercent: routeProgressPercent ?? this.routeProgressPercent,
      laneGuidance: laneGuidance ?? this.laneGuidance,
      speedLimit: speedLimit ?? this.speedLimit,
      rerouteState: rerouteState ?? this.rerouteState,
      isOffRoute: isOffRoute ?? this.isOffRoute,
      simulation: simulation ?? this.simulation,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      simulationMode: simulationMode ?? this.simulationMode,
      safety: safety ?? this.safety,
      startedAt: startedAt ?? this.startedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationSession && sessionId == other.sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}
