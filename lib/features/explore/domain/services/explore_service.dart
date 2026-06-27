import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_marker.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/explore/domain/entities/explore_result.dart';
import 'package:rihla/features/explore/domain/entities/explore_search.dart';
import 'package:rihla/features/explore/domain/repositories/explore_repository.dart';

/// Business logic for Explore discovery.
abstract class ExploreService {
  Future<ExploreResult> search(ExploreSearch search);

  Future<List<ExplorePlace>> getPlacesByCategory({
    required ExploreCategory category,
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 50,
  });

  Future<List<ExploreJourneyRecommendation>> getJourneyRecommendations({
    required double latitude,
    required double longitude,
    double? remainingFuelPercent,
    double? remainingBatteryPercent,
    int? journeyDurationMinutes,
    bool trafficHeavy = false,
    bool weatherAdverse = false,
  });

  List<ExploreMarker> clusterMarkers({
    required List<ExplorePlace> places,
    required double zoom,
    double? north,
    double? south,
    double? east,
    double? west,
  });
}
