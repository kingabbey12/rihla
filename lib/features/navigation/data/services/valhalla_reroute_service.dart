import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/navigation/domain/services/reroute_service.dart';
import 'package:rihla/features/routing/domain/entities/route_options.dart';
import 'package:rihla/features/routing/domain/entities/route_point.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/services/route_service.dart';

/// Production reroute using the live [RouteService].
class ValhallaRerouteService implements RerouteService {
  ValhallaRerouteService(this._routeService);

  final RouteService _routeService;

  @override
  Future<RouteSummary> recalculate({
    required JourneySummary journey,
    required RouteSummary currentRoute,
  }) async {
    final result = await _routeService.calculateRoutes(
      RouteRequest(
        origin: RoutePoint(
          id: journey.origin.id ?? 'origin',
          name: journey.origin.name,
          latitude: journey.origin.latitude,
          longitude: journey.origin.longitude,
        ),
        destination: RoutePoint(
          id: journey.destination.id ?? 'destination',
          name: journey.destination.name,
          latitude: journey.destination.latitude,
          longitude: journey.destination.longitude,
        ),
        options: RouteOptions(profiles: [currentRoute.profile]),
      ),
    );

    if (result.routes.isEmpty) {
      throw Exception('No reroute available');
    }
    return result.routes.first;
  }
}
