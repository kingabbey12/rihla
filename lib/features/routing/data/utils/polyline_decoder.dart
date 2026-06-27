import 'dart:math' as math;

import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';

/// Decodes Google/Valhalla encoded polylines.
///
/// Valhalla uses precision 6 (1e-6 degree units). Mapbox/Google use precision 5.
abstract final class PolylineDecoder {
  /// Decodes [encoded] into a list of [RouteCoordinate]s.
  static List<RouteCoordinate> decode(
    String encoded, {
    int precision = 6,
  }) {
    if (encoded.isEmpty) return [];

    final coordinates = <RouteCoordinate>[];
    var index = 0;
    var lat = 0;
    var lng = 0;
    final factor = math.pow(10, precision).toInt();

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      coordinates.add(
        RouteCoordinate(
          latitude: lat / factor,
          longitude: lng / factor,
        ),
      );
    }

    return coordinates;
  }
}
