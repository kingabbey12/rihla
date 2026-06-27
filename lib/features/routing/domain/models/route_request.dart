import 'package:rihla/features/routing/domain/entities/route_options.dart';
import 'package:rihla/features/routing/domain/entities/route_point.dart';

/// Input for a route calculation request.
class RouteRequest {
  const RouteRequest({
    required this.origin,
    required this.destination,
    this.waypoints = const [],
    this.options = RouteOptions.defaults,
  });

  final RoutePoint origin;
  final RoutePoint destination;
  final List<RoutePoint> waypoints;
  final RouteOptions options;

  /// All locations in visit order: origin → waypoints → destination.
  List<RoutePoint> get allPoints => [origin, ...waypoints, destination];
}
