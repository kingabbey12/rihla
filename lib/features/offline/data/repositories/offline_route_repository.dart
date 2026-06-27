import 'package:rihla/features/routing/data/repositories/route_repository_impl.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/domain/repositories/route_repository.dart';
import 'package:rihla/features/routing/domain/services/route_service.dart';

/// Offline route repository wrapping [OfflineRouteService].
class OfflineRouteRepository implements RouteRepository {
  OfflineRouteRepository(RouteService service)
      : _delegate = RouteRepositoryImpl(service);

  final RouteRepositoryImpl _delegate;

  @override
  Future<RouteResult> getRoutes(RouteRequest request) =>
      _delegate.getRoutes(request);
}
