import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';

/// High-level route operations with validation and error mapping.
abstract class RouteRepository {
  Future<RouteResult> getRoutes(RouteRequest request);
}
