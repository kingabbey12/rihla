import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/domain/repositories/route_repository.dart';

/// Delegates routing to online or offline repository based on connectivity.
class OfflineAwareRouteRepository implements RouteRepository {
  OfflineAwareRouteRepository({
    required this.isOffline,
    required RouteRepository online,
    required RouteRepository offline,
  })  : _online = online,
        _offline = offline;

  final bool Function() isOffline;
  final RouteRepository _online;
  final RouteRepository _offline;

  @override
  Future<RouteResult> getRoutes(RouteRequest request) {
    return isOffline() ? _offline.getRoutes(request) : _online.getRoutes(request);
  }
}
