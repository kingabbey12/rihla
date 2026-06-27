import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/navigation/domain/services/reroute_service.dart';
import 'package:rihla/features/routing/data/services/mock_route_service.dart';
import 'package:rihla/features/routing/domain/entities/route_point.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';

/// Mock reroute using the existing mock route service.
class MockRerouteService implements RerouteService {
  MockRerouteService({this.simulatedDelay = const Duration(milliseconds: 600)});

  final Duration simulatedDelay;

  @override
  Future<RouteSummary> recalculate({
    required JourneySummary journey,
    required RouteSummary currentRoute,
  }) async {
    await Future<void>.delayed(simulatedDelay);
    final service = MockRouteService(simulatedDelay: Duration.zero);
    final result = await service.calculateRoutes(
      RouteRequest(
        origin: RoutePoint(
          id: journey.origin.id,
          name: journey.origin.name,
          latitude: journey.origin.latitude,
          longitude: journey.origin.longitude,
        ),
        destination: RoutePoint(
          id: journey.destination.id,
          name: journey.destination.name,
          latitude: journey.destination.latitude,
          longitude: journey.destination.longitude,
        ),
      ),
    );
    final rerouted = result.routes.firstWhere(
      (r) => r.profile == currentRoute.profile,
      orElse: () => result.primary ?? result.routes.first,
    );
    return rerouted.copyWithId('reroute_${DateTime.now().millisecondsSinceEpoch}');
  }
}

extension on RouteSummary {
  RouteSummary copyWithId(String id) => RouteSummary(
        id: id,
        profile: profile,
        distanceKm: distanceKm,
        durationSeconds: durationSeconds,
        coordinates: coordinates,
        journeyScore: journeyScore,
        fuelEstimateLiters: fuelEstimateLiters,
        trafficSummary: trafficSummary,
        safetySummary: safetySummary,
        encodedPolyline: encodedPolyline,
      );
}
