import 'dart:math' as math;

import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';

/// A coloured slice of the route polyline representing congestion level.
class RouteTrafficSegment {
  const RouteTrafficSegment({
    required this.coordinates,
    required this.density,
  });

  final List<RouteCoordinate> coordinates;
  final TrafficDensity density;
}

/// Splits a route into coloured traffic segments for map rendering.
///
/// Uses incident proximity when available, otherwise interpolates densities
/// along the corridor from the overall snapshot reading.
List<RouteTrafficSegment> buildRouteTrafficSegments({
  required List<RouteCoordinate> route,
  TrafficSnapshot? snapshot,
  int segmentCount = 5,
}) {
  if (route.length < 2) return const [];

  final count = segmentCount.clamp(2, 8);
  final chunk = (route.length / count).ceil().clamp(1, route.length);
  final segments = <RouteTrafficSegment>[];

  for (var i = 0; i < route.length; i += chunk) {
    final end = math.min(i + chunk + 1, route.length);
    if (end - i < 2) continue;
    final slice = route.sublist(i, end);
    final progress = i / math.max(1, route.length - 1);
    segments.add(
      RouteTrafficSegment(
        coordinates: slice,
        density: _densityForSlice(
          progress: progress,
          snapshot: snapshot,
          slice: slice,
        ),
      ),
    );
  }

  return segments;
}

TrafficDensity _densityForSlice({
  required double progress,
  required TrafficSnapshot? snapshot,
  required List<RouteCoordinate> slice,
}) {
  if (snapshot == null) return TrafficDensity.freeFlow;

  final base = snapshot.density;
  if (snapshot.incidents.isEmpty) {
    return _interpolateDensity(base, progress);
  }

  final mid = slice[slice.length ~/ 2];
  var nearestDelay = 0;
  for (final incident in snapshot.incidents) {
    final dLat = mid.latitude - incident.latitude;
    final dLng = mid.longitude - incident.longitude;
    final dist2 = dLat * dLat + dLng * dLng;
    if (dist2 < 0.0004 && incident.delayMinutes > nearestDelay) {
      nearestDelay = incident.delayMinutes;
    }
  }

  if (nearestDelay >= 15) return TrafficDensity.standstill;
  if (nearestDelay >= 8) return TrafficDensity.heavy;
  if (nearestDelay >= 3) return TrafficDensity.moderate;

  return _interpolateDensity(base, progress);
}

TrafficDensity _interpolateDensity(TrafficDensity base, double progress) {
  return switch (base) {
    TrafficDensity.freeFlow || TrafficDensity.light => TrafficDensity.freeFlow,
    TrafficDensity.moderate =>
      progress > 0.55 ? TrafficDensity.heavy : TrafficDensity.moderate,
    TrafficDensity.heavy =>
      progress > 0.35 ? TrafficDensity.heavy : TrafficDensity.moderate,
    TrafficDensity.standstill => TrafficDensity.standstill,
  };
}

/// Hex colours for MapLibre line rendering.
String trafficColorHex(TrafficDensity density) => switch (density) {
      TrafficDensity.freeFlow || TrafficDensity.light => '#22C55E',
      TrafficDensity.moderate => '#F59E0B',
      TrafficDensity.heavy => '#EF4444',
      TrafficDensity.standstill => '#991B1B',
    };
