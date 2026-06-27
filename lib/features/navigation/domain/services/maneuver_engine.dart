import 'package:rihla/features/navigation/domain/entities/maneuver_type.dart';
import 'package:rihla/features/navigation/domain/entities/route_maneuver_step.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Builds turn-by-turn maneuver steps from a route polyline.
abstract class ManeuverEngine {
  List<RouteManeuverStep> buildSteps(RouteSummary route);

  String instructionFor(ManeuverType type, String nextRoad);
}
