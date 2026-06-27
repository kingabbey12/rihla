import 'dart:math' as math;

import 'package:rihla/features/navigation/domain/entities/maneuver_type.dart';
import 'package:rihla/features/navigation/domain/entities/route_maneuver_step.dart';
import 'package:rihla/features/navigation/domain/services/maneuver_engine.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Derives maneuver steps from polyline bearing changes.
class PolylineManeuverEngine implements ManeuverEngine {
  static const _roads = [
    'King Fahd Road',
    'Northern Ring Road',
    'Olaya Street',
    'Eastern Ring Road',
    'Airport Road',
    'Exit 12',
  ];

  @override
  List<RouteManeuverStep> buildSteps(RouteSummary route) {
    final coords = route.coordinates;
    if (coords.length < 2) {
      return [
        RouteManeuverStep(
          type: ManeuverType.arrive,
          distanceFromStartKm: route.distanceKm,
          currentRoad: _roads.first,
          nextRoad: route.journeyDestinationName,
          coordinateIndex: coords.isEmpty ? 0 : coords.length - 1,
        ),
      ];
    }

    final cumulativeKm = _cumulativeDistances(coords, route.distanceKm);
    final steps = <RouteManeuverStep>[
      RouteManeuverStep(
        type: ManeuverType.continueStraight,
        distanceFromStartKm: 0,
        currentRoad: _roads.first,
        nextRoad: _roads[1 % _roads.length],
        coordinateIndex: 0,
      ),
    ];

    for (var i = 1; i < coords.length - 1; i++) {
      final prev = _bearing(coords[i - 1], coords[i]);
      final next = _bearing(coords[i], coords[i + 1]);
      final delta = _normalizeAngle(next - prev);
      final type = _typeForDelta(delta, i);
      if (type == ManeuverType.continueStraight && steps.length > 1) continue;

      steps.add(
        RouteManeuverStep(
          type: type,
          distanceFromStartKm: cumulativeKm[i],
          currentRoad: _roads[i % _roads.length],
          nextRoad: _roads[(i + 1) % _roads.length],
          coordinateIndex: i,
        ),
      );
    }

    steps.add(
      RouteManeuverStep(
        type: ManeuverType.arrive,
        distanceFromStartKm: route.distanceKm,
        currentRoad: _roads.last,
        nextRoad: 'Destination',
        coordinateIndex: coords.length - 1,
      ),
    );

    return steps;
  }

  @override
  String instructionFor(ManeuverType type, String nextRoad) {
    return switch (type) {
      ManeuverType.continueStraight => 'Continue straight',
      ManeuverType.turnLeft => 'Turn left onto $nextRoad',
      ManeuverType.turnRight => 'Turn right onto $nextRoad',
      ManeuverType.slightLeft => 'Keep left toward $nextRoad',
      ManeuverType.slightRight => 'Keep right toward $nextRoad',
      ManeuverType.uTurn => 'Make a U-turn',
      ManeuverType.merge => 'Merge onto $nextRoad',
      ManeuverType.exit => 'Take the exit toward $nextRoad',
      ManeuverType.roundabout => 'At the roundabout, take exit to $nextRoad',
      ManeuverType.arrive => 'You have arrived at your destination',
    };
  }

  ManeuverType _typeForDelta(double delta, int index) {
    if (index % 11 == 7) return ManeuverType.roundabout;
    if (index % 9 == 5) return ManeuverType.merge;
    if (index % 8 == 4) return ManeuverType.exit;

    final abs = delta.abs();
    if (abs < 15) return ManeuverType.continueStraight;
    if (abs < 35) return delta > 0 ? ManeuverType.slightRight : ManeuverType.slightLeft;
    if (abs < 120) return delta > 0 ? ManeuverType.turnRight : ManeuverType.turnLeft;
    return ManeuverType.uTurn;
  }

  List<double> _cumulativeDistances(
    List<RouteCoordinate> coords,
    double totalKm,
  ) {
    if (coords.length <= 1) return [0];
    final segmentKm = totalKm / (coords.length - 1);
    return List.generate(coords.length, (i) => i * segmentKm);
  }

  double _bearing(RouteCoordinate from, RouteCoordinate to) {
    final phi1 = from.latitude * math.pi / 180;
    final phi2 = to.latitude * math.pi / 180;
    final dLambda = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    return math.atan2(y, x) * 180 / math.pi;
  }

  double _normalizeAngle(double degrees) {
    var d = degrees % 360;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d;
  }
}

extension on RouteSummary {
  String get journeyDestinationName => 'Destination';
}
