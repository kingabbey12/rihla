import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';

/// Detects when the driver leaves the route corridor.
abstract class RouteDeviationDetector {
  double distanceToRouteMeters({
    required LocationPosition position,
    required List<RouteCoordinate> coordinates,
  });

  bool isOffRoute({
    required LocationPosition position,
    required List<RouteCoordinate> coordinates,
    double thresholdMeters,
  });
}
