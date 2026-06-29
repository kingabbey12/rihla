/// Validation helpers for geographic coordinates used across routing and
/// journey planning. Rejects the values that silently break a Valhalla request:
/// null, NaN, infinite, out-of-range, and the (0,0) "null island" default.
abstract final class CoordinateValidation {
  /// Whether [lat]/[lng] form a usable real-world coordinate.
  static bool isValid(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) {
      return false;
    }
    // (0,0) is in the Gulf of Guinea — almost always an uninitialised default
    // rather than a real fix, so we treat it as invalid.
    if (lat == 0 && lng == 0) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }

  /// Human/loggable reason a coordinate pair is invalid, or null if valid.
  static String? invalidReason(double? lat, double? lng) {
    if (lat == null || lng == null) return 'null';
    if (lat.isNaN || lng.isNaN) return 'NaN';
    if (lat.isInfinite || lng.isInfinite) return 'infinite';
    if (lat == 0 && lng == 0) return 'zero/null-island';
    if (lat < -90 || lat > 90) return 'lat-out-of-range';
    if (lng < -180 || lng > 180) return 'lng-out-of-range';
    return null;
  }

  /// `"lat,lng"` formatted to 6 decimals for logs.
  static String format(double lat, double lng) =>
      '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
}
