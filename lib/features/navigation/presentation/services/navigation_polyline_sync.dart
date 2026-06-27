import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';

/// Syncs the active route polyline to the map layer.
class NavigationPolylineSync {
  NavigationPolylineSync(this._ref);

  final Ref _ref;

  void setRoute(RouteSummary route) {
    _ref.read(mapRoutePolylineProvider.notifier).set(route.coordinates);
  }

  void clear() {
    _ref.read(mapRoutePolylineProvider.notifier).clear();
  }

  void setCoordinates(List<RouteCoordinate> coordinates) {
    _ref.read(mapRoutePolylineProvider.notifier).set(coordinates);
  }
}

final navigationPolylineSyncProvider = Provider<NavigationPolylineSync>(
  (ref) => NavigationPolylineSync(ref),
);
