import 'package:rihla/features/navigation/domain/entities/lane_guidance.dart';
import 'package:rihla/features/navigation/domain/entities/maneuver_type.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_maneuver.dart';
import 'package:rihla/features/navigation/domain/entities/route_maneuver_step.dart';
import 'package:rihla/features/navigation/domain/entities/speed_limit.dart';
import 'package:rihla/features/navigation/domain/services/maneuver_engine.dart';

/// Shared helpers for resolving maneuvers, lanes, and speed limits.
class NavigationSessionHelpers {
  const NavigationSessionHelpers(this._maneuverEngine);

  final ManeuverEngine _maneuverEngine;

  ({int stepIndex, RouteManeuverStep step}) resolveStep({
    required List<RouteManeuverStep> steps,
    required double distanceTraveledKm,
  }) {
    if (steps.isEmpty) {
      throw StateError('Maneuver steps cannot be empty');
    }
    var index = 0;
    for (var i = steps.length - 1; i >= 0; i--) {
      if (distanceTraveledKm >= steps[i].distanceFromStartKm) {
        index = i;
        break;
      }
    }
    return (stepIndex: index, step: steps[index]);
  }

  NavigationManeuver buildManeuver({
    required List<RouteManeuverStep> steps,
    required int stepIndex,
    required double distanceTraveledKm,
  }) {
    final step = steps[stepIndex];
    final nextStep = stepIndex + 1 < steps.length ? steps[stepIndex + 1] : step;
    final distanceToManeuver = (nextStep.distanceFromStartKm - distanceTraveledKm)
        .clamp(0.0, double.infinity);

    return NavigationManeuver(
      type: nextStep.type,
      instruction: _maneuverEngine.instructionFor(nextStep.type, nextStep.nextRoad),
      distanceToManeuverKm: distanceToManeuver,
      currentRoad: step.currentRoad,
      nextRoad: nextStep.nextRoad,
      isPlaceholder: false,
    );
  }

  LaneGuidance laneGuidanceFor(ManeuverType type) {
    final lanes = switch (type) {
      ManeuverType.turnLeft => const [
          LaneIndicator(direction: LaneDirection.straight, isRecommended: false),
          LaneIndicator(direction: LaneDirection.left, isRecommended: true),
        ],
      ManeuverType.turnRight => const [
          LaneIndicator(direction: LaneDirection.straight, isRecommended: false),
          LaneIndicator(direction: LaneDirection.right, isRecommended: true),
        ],
      ManeuverType.slightLeft => const [
          LaneIndicator(direction: LaneDirection.slightLeft, isRecommended: true),
          LaneIndicator(direction: LaneDirection.straight, isRecommended: false),
        ],
      ManeuverType.slightRight => const [
          LaneIndicator(direction: LaneDirection.straight, isRecommended: false),
          LaneIndicator(direction: LaneDirection.slightRight, isRecommended: true),
        ],
      ManeuverType.merge => const [
          LaneIndicator(direction: LaneDirection.straight, isRecommended: false),
          LaneIndicator(direction: LaneDirection.right, isRecommended: true),
        ],
      ManeuverType.roundabout => const [
          LaneIndicator(direction: LaneDirection.right, isRecommended: true),
          LaneIndicator(direction: LaneDirection.straight, isRecommended: false),
        ],
      _ => const [
          LaneIndicator(direction: LaneDirection.straight, isRecommended: true),
        ],
    };
    return LaneGuidance(lanes: lanes, isPlaceholder: true);
  }

  SpeedLimit speedLimitFor(ManeuverType type) {
    final limit = switch (type) {
      ManeuverType.exit => 60,
      ManeuverType.roundabout => 40,
      ManeuverType.merge => 80,
      ManeuverType.arrive => 30,
      _ => 80,
    };
    return SpeedLimit(limitKmh: limit, isPlaceholder: true);
  }
}
