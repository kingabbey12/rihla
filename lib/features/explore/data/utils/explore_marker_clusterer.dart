import 'package:rihla/features/explore/domain/entities/explore_marker.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';

/// Grid-based marker clustering for Explore map display.
abstract final class ExploreMarkerClusterer {
  static List<ExploreMarker> cluster({
    required List<ExplorePlace> places,
    required double zoom,
    double? north,
    double? south,
    double? east,
    double? west,
  }) {
    if (places.isEmpty) return const [];

    final cellSize = _cellSizeForZoom(zoom);
    final buckets = <String, List<ExplorePlace>>{};

    for (final place in places) {
      if (north != null &&
          south != null &&
          east != null &&
          west != null &&
          (place.latitude > north ||
              place.latitude < south ||
              place.longitude < west ||
              place.longitude > east)) {
        continue;
      }
      final key =
          '${(place.latitude / cellSize).floor()}_${(place.longitude / cellSize).floor()}';
      buckets.putIfAbsent(key, () => []).add(place);
    }

    final markers = <ExploreMarker>[];
    for (final entry in buckets.entries) {
      final group = entry.value;
      if (group.length == 1) {
        final place = group.first;
        markers.add(
          ExploreMarker(
            id: 'marker_${place.id}',
            latitude: place.latitude,
            longitude: place.longitude,
            place: place,
          ),
        );
      } else {
        final avgLat =
            group.map((p) => p.latitude).reduce((a, b) => a + b) / group.length;
        final avgLng =
            group.map((p) => p.longitude).reduce((a, b) => a + b) / group.length;
        markers.add(
          ExploreMarker(
            id: 'cluster_${entry.key}',
            latitude: avgLat,
            longitude: avgLng,
            count: group.length,
            isCluster: true,
          ),
        );
      }
    }
    return markers;
  }

  static double _cellSizeForZoom(double zoom) {
    if (zoom >= 15) return 0.002;
    if (zoom >= 13) return 0.008;
    if (zoom >= 11) return 0.02;
    if (zoom >= 9) return 0.05;
    return 0.12;
  }
}
