import 'dart:math' as math;

/// Geographic helpers for Explore discovery.
abstract final class ExploreGeoUtil {
  static double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static int etaMinutes(double distanceKm, {double avgSpeedKmh = 45}) {
    if (distanceKm <= 0) return 0;
    return (distanceKm / avgSpeedKmh * 60).ceil().clamp(1, 999);
  }

  static bool inViewport({
    required double latitude,
    required double longitude,
    double? north,
    double? south,
    double? east,
    double? west,
  }) {
    if (north == null || south == null || east == null || west == null) {
      return true;
    }
    return latitude <= north &&
        latitude >= south &&
        longitude >= west &&
        longitude <= east;
  }

  static double _toRadians(double deg) => deg * math.pi / 180;
}
