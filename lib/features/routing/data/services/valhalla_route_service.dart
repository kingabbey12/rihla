import 'package:rihla/features/routing/data/datasources/valhalla_route_datasource.dart';
import 'package:rihla/features/routing/data/mappers/valhalla_route_mapper.dart';
import 'package:rihla/features/routing/domain/entities/route_options.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/domain/services/route_service.dart';

/// Production route service backed by the Valhalla HTTP API.
class ValhallaRouteService implements RouteService {
  ValhallaRouteService(this._datasource);

  final ValhallaRouteDatasource _datasource;

  @override
  Future<RouteResult> calculateRoutes(RouteRequest request) async {
    final body = _buildRequestBody(request);
    final response = await _datasource.fetchRoute(body);
    return ValhallaRouteMapper.fromResponse(
      response,
      profiles: request.options.profiles,
    );
  }

  Map<String, dynamic> _buildRequestBody(RouteRequest request) {
    final locations = request.allPoints
        .map((p) => {'lat': p.latitude, 'lon': p.longitude})
        .toList();

    final costingOptions = <String, dynamic>{
      'use_highways': request.options.avoidHighways ? 0.0 : 1.0,
      'use_tolls': request.options.avoidTolls ? 0.0 : 1.0,
    };

    return {
      'locations': locations,
      'costing': 'auto',
      'alternates': request.options.alternateCount,
      'units': request.options.units == RouteUnits.kilometers
          ? 'kilometers'
          : 'miles',
      'language': 'en-US',
      'directions_options': {'units': 'kilometers'},
      'costing_options': {'auto': costingOptions},
    };
  }
}
