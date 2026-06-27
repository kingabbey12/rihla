import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';

/// Contract for external route calculation (Valhalla or mock).
abstract class RouteService {
  Future<RouteResult> calculateRoutes(RouteRequest request);
}
