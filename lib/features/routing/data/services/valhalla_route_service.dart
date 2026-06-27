import 'package:rihla/features/routing/data/datasources/valhalla_route_datasource.dart';
import 'package:rihla/features/routing/data/mappers/valhalla_route_mapper.dart';
import 'package:rihla/features/routing/domain/entities/route_options.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/domain/services/route_service.dart';

/// Production route service backed by the Valhalla HTTP API.
class ValhallaRouteService implements RouteService {
  ValhallaRouteService(this._datasource);

  final ValhallaRouteDatasource _datasource;

  @override
  Future<RouteResult> calculateRoutes(RouteRequest request) async {
    final profiles = request.options.profiles;
    final routes = <RouteSummary>[];

    for (var i = 0; i < profiles.length; i++) {
      final profile = profiles[i];
      final body = _buildRequestBody(request, profile: profile);
      final response = await _datasource.fetchRoute(body);
      final result = ValhallaRouteMapper.fromResponse(
        response,
        profiles: [profile],
      );
      if (result.routes.isNotEmpty) {
        routes.add(result.routes.first.copyWithProfile(profile, i));
      }
    }

    if (routes.isEmpty) {
      final body = _buildRequestBody(
        request,
        profile: RouteProfile.fast,
        alternates: request.options.alternateCount,
      );
      final response = await _datasource.fetchRoute(body);
      return ValhallaRouteMapper.fromResponse(
        response,
        profiles: profiles,
      );
    }

    return RouteResult(
      routes: routes,
      primaryRouteId: routes.first.id,
    );
  }

  Map<String, dynamic> _buildRequestBody(
    RouteRequest request, {
    required RouteProfile profile,
    int alternates = 0,
  }) {
    final locations = request.allPoints
        .map((p) => {'lat': p.latitude, 'lon': p.longitude})
        .toList();

    final costingOptions = _costingFor(profile, request.options);

    return {
      'locations': locations,
      'costing': 'auto',
      if (alternates > 0) 'alternates': alternates,
      'units': request.options.units == RouteUnits.kilometers
          ? 'kilometers'
          : 'miles',
      'language': 'en-US',
      'directions_options': {'units': 'kilometers'},
      'costing_options': {'auto': costingOptions},
    };
  }

  Map<String, dynamic> _costingFor(RouteProfile profile, RouteOptions options) {
    return switch (profile) {
      RouteProfile.fast => {
          'use_highways': options.avoidHighways ? 0.0 : 1.0,
          'use_tolls': options.avoidTolls ? 0.0 : 1.0,
          'top_speed': 130,
        },
      RouteProfile.safe => {
          'use_highways': 0.3,
          'use_tolls': options.avoidTolls ? 0.0 : 0.5,
          'use_ferry': 0,
          'top_speed': 100,
        },
      RouteProfile.eco => {
          'use_highways': 0.5,
          'use_tolls': 0,
          'top_speed': 90,
          'fuel_factor': 1.2,
        },
      RouteProfile.scenic => {
          'use_highways': 0.0,
          'use_tolls': 0,
          'use_living_streets': 0.8,
          'top_speed': 80,
        },
    };
  }
}

extension _RouteSummaryProfile on RouteSummary {
  RouteSummary copyWithProfile(RouteProfile profile, int index) {
    return RouteSummary(
      id: 'route_${profile.name}_$index',
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
}
