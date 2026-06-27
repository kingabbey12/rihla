import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/explore/domain/entities/explore_result.dart';
import 'package:rihla/features/explore/domain/entities/explore_search.dart';

/// Journey-context recommendation for Explore.
class ExploreJourneyRecommendation {
  const ExploreJourneyRecommendation({
    required this.places,
    required this.reason,
    required this.category,
    required this.priority,
  });

  final List<ExplorePlace> places;
  final String reason;
  final ExploreCategory category;
  final int priority;
}

abstract class ExploreRepository {
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
}
