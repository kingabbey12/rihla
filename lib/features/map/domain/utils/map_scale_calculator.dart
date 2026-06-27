import 'dart:math' as math;

/// Utilities for computing the map scale bar from zoom + latitude.
abstract final class MapScaleCalculator {
  /// Web Mercator ground resolution at the equator for zoom 0, tile size 256.
  static const double _equatorMetersPerPixel = 156543.03392;

  /// Meters represented by a single screen pixel at [latitude] and [zoom].
  static double metersPerPixel(double latitude, double zoom) {
    final latRad = latitude * math.pi / 180.0;
    return _equatorMetersPerPixel * math.cos(latRad) / math.pow(2, zoom);
  }

  /// Returns a "nice" rounded distance (in meters) at or below [maxMeters].
  static double niceDistance(double maxMeters) {
    if (maxMeters <= 0) return 0;
    final magnitude = math.pow(10, (math.log(maxMeters) / math.ln10).floor());
    final residual = maxMeters / magnitude;
    final nice = switch (residual) {
      >= 5 => 5.0,
      >= 3 => 3.0,
      >= 2 => 2.0,
      _ => 1.0,
    };
    return nice * magnitude;
  }

  /// Human-readable label for a scale distance in meters.
  static String label(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return km == km.roundToDouble()
          ? '${km.toInt()} km'
          : '${km.toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }
}
