import 'package:rihla/features/explore/domain/entities/explore_place.dart';

/// Map marker for Explore clustering and display.
class ExploreMarker {
  const ExploreMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.place,
    this.count = 1,
    this.isCluster = false,
  });

  final String id;
  final double latitude;
  final double longitude;
  final ExplorePlace? place;
  final int count;
  final bool isCluster;
}
