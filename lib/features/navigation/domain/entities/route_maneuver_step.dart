import 'package:rihla/features/navigation/domain/entities/maneuver_type.dart';

/// A single maneuver step along a route polyline.
class RouteManeuverStep {
  const RouteManeuverStep({
    required this.type,
    required this.distanceFromStartKm,
    required this.currentRoad,
    required this.nextRoad,
    required this.coordinateIndex,
  });

  final ManeuverType type;
  final double distanceFromStartKm;
  final String currentRoad;
  final String nextRoad;
  final int coordinateIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteManeuverStep &&
          type == other.type &&
          distanceFromStartKm == other.distanceFromStartKm &&
          coordinateIndex == other.coordinateIndex;

  @override
  int get hashCode => Object.hash(type, distanceFromStartKm, coordinateIndex);
}
