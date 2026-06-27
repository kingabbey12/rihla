import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/navigation/data/services/polyline_route_deviation_detector.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';

void main() {
  late PolylineRouteDeviationDetector detector;

  setUp(() {
    detector = PolylineRouteDeviationDetector();
  });

  const coords = [
    RouteCoordinate(latitude: 24.7136, longitude: 46.6753),
    RouteCoordinate(latitude: 24.7120, longitude: 46.6740),
    RouteCoordinate(latitude: 24.7113, longitude: 46.6743),
  ];

  test('position on route is not off route', () {
    final onRoute = LocationPosition(
      latitude: 24.7120,
      longitude: 46.6740,
      accuracy: 5,
      timestamp: DateTime.now(),
    );
    expect(
      detector.isOffRoute(position: onRoute, coordinates: coords),
      isFalse,
    );
  });

  test('position far from route is off route', () {
    final offRoute = LocationPosition(
      latitude: 24.75,
      longitude: 46.75,
      accuracy: 5,
      timestamp: DateTime.now(),
    );
    expect(
      detector.isOffRoute(position: offRoute, coordinates: coords),
      isTrue,
    );
  });
}
