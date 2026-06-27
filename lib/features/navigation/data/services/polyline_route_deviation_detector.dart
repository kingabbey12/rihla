import 'dart:math' as math;

import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/navigation/domain/services/route_deviation_detector.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';

/// Geometric deviation detection against the route polyline.
class PolylineRouteDeviationDetector implements RouteDeviationDetector {
  @override
  double distanceToRouteMeters({
    required LocationPosition position,
    required List<RouteCoordinate> coordinates,
  }) {
    if (coordinates.isEmpty) return double.infinity;
    if (coordinates.length == 1) {
      return _haversineMeters(
        position.latitude,
        position.longitude,
        coordinates.first.latitude,
        coordinates.first.longitude,
      );
    }

    var minDistance = double.infinity;
    for (var i = 0; i < coordinates.length - 1; i++) {
      final a = coordinates[i];
      final b = coordinates[i + 1];
      final d = _pointToSegmentMeters(
        position.latitude,
        position.longitude,
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
      if (d < minDistance) minDistance = d;
    }
    return minDistance;
  }

  @override
  bool isOffRoute({
    required LocationPosition position,
    required List<RouteCoordinate> coordinates,
    double thresholdMeters = 50,
  }) {
    return distanceToRouteMeters(
          position: position,
          coordinates: coordinates,
        ) >
        thresholdMeters;
  }

  double _pointToSegmentMeters(
    double lat,
    double lng,
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dx = lat2 - lat1;
    final dy = lng2 - lng1;
    if (dx == 0 && dy == 0) {
      return _haversineMeters(lat, lng, lat1, lng1);
    }
    final t = ((lat - lat1) * dx + (lng - lng1) * dy) / (dx * dx + dy * dy);
    final clamped = t.clamp(0.0, 1.0);
    final projLat = lat1 + clamped * dx;
    final projLng = lng1 + clamped * dy;
    return _haversineMeters(lat, lng, projLat, projLng);
  }

  double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dPhi = (lat2 - lat1) * math.pi / 180;
    final dLambda = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
