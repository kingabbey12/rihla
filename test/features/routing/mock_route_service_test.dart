import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/routing/data/services/mock_route_service.dart';
import 'package:rihla/features/routing/domain/entities/route_point.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';

void main() {
  const origin = RoutePoint(latitude: 24.7136, longitude: 46.6753);
  const destination = RoutePoint(latitude: 24.7113, longitude: 46.6743);

  late MockRouteService service;

  setUp(() {
    service = MockRouteService(simulatedDelay: Duration.zero);
  });

  test('returns four profile alternatives', () async {
    final result = await service.calculateRoutes(
      const RouteRequest(origin: origin, destination: destination),
    );
    expect(result.routes.length, 4);
    expect(
      result.routes.map((r) => r.profile).toSet(),
      equals(RouteProfile.values.toSet()),
    );
  });

  test('each route has coordinates and metrics', () async {
    final result = await service.calculateRoutes(
      const RouteRequest(origin: origin, destination: destination),
    );
    for (final route in result.routes) {
      expect(route.distanceKm, greaterThan(0));
      expect(route.durationSeconds, greaterThan(0));
      expect(route.coordinates.length, greaterThan(2));
      expect(route.journeyScore, inInclusiveRange(0, 100));
    }
  });

  test('supports waypoints', () async {
    final result = await service.calculateRoutes(
      const RouteRequest(
        origin: origin,
        destination: destination,
        waypoints: [
          RoutePoint(latitude: 24.72, longitude: 46.68),
        ],
      ),
    );
    expect(result.routes, isNotEmpty);
  });
}
