import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/explore/domain/entities/explore_result.dart';
import 'package:rihla/features/explore/domain/entities/explore_search.dart';
import 'package:rihla/features/explore/domain/repositories/explore_repository.dart';
import 'package:rihla/features/explore/domain/services/explore_service.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  ExploreRepositoryImpl(this._service);

  final ExploreService _service;

  @override
  Future<ExploreResult> search(ExploreSearch search) => _service.search(search);

  @override
  Future<List<ExplorePlace>> getPlacesByCategory({
    required ExploreCategory category,
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 50,
  }) =>
      _service.getPlacesByCategory(
        category: category,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      );

  @override
  Future<List<ExploreJourneyRecommendation>> getJourneyRecommendations({
    required double latitude,
    required double longitude,
    double? remainingFuelPercent,
    double? remainingBatteryPercent,
    int? journeyDurationMinutes,
    bool trafficHeavy = false,
    bool weatherAdverse = false,
  }) =>
      _service.getJourneyRecommendations(
        latitude: latitude,
        longitude: longitude,
        remainingFuelPercent: remainingFuelPercent,
        remainingBatteryPercent: remainingBatteryPercent,
        journeyDurationMinutes: journeyDurationMinutes,
        trafficHeavy: trafficHeavy,
        weatherAdverse: weatherAdverse,
      );
}
