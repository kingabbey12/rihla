import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Result of a successful route calculation with alternatives.
class RouteResult {
  const RouteResult({
    required this.routes,
    this.primaryRouteId,
  });

  final List<RouteSummary> routes;
  final String? primaryRouteId;

  RouteSummary? get primary => routes.isEmpty
      ? null
      : routes.firstWhere(
          (r) => r.id == primaryRouteId,
          orElse: () => routes.first,
        );

  RouteSummary? routeById(String id) {
    for (final r in routes) {
      if (r.id == id) return r;
    }
    return null;
  }
}
