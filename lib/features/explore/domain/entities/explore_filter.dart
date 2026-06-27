import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';

/// Filters for Explore discovery queries.
class ExploreFilter {
  const ExploreFilter({
    this.maxDistanceKm = 25,
    this.minRating,
    this.openNow = false,
    this.open24Hours = false,
    this.evConnectorType,
    this.fuelType,
    this.freeParking = false,
    this.paidParking = false,
    this.accessible = false,
    this.familyFriendly = false,
    this.category,
  });

  final double maxDistanceKm;
  final double? minRating;
  final bool openNow;
  final bool open24Hours;
  final String? evConnectorType;
  final String? fuelType;
  final bool freeParking;
  final bool paidParking;
  final bool accessible;
  final bool familyFriendly;
  final ExploreCategory? category;

  static const defaults = ExploreFilter();

  ExploreFilter copyWith({
    double? maxDistanceKm,
    double? minRating,
    bool? openNow,
    bool? open24Hours,
    String? evConnectorType,
    String? fuelType,
    bool? freeParking,
    bool? paidParking,
    bool? accessible,
    bool? familyFriendly,
    ExploreCategory? category,
  }) =>
      ExploreFilter(
        maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
        minRating: minRating ?? this.minRating,
        openNow: openNow ?? this.openNow,
        open24Hours: open24Hours ?? this.open24Hours,
        evConnectorType: evConnectorType ?? this.evConnectorType,
        fuelType: fuelType ?? this.fuelType,
        freeParking: freeParking ?? this.freeParking,
        paidParking: paidParking ?? this.paidParking,
        accessible: accessible ?? this.accessible,
        familyFriendly: familyFriendly ?? this.familyFriendly,
        category: category ?? this.category,
      );

  bool matches(ExplorePlace place) {
    if (category != null && place.category != category) return false;
    if (minRating != null &&
        (place.rating == null || place.rating! < minRating!)) {
      return false;
    }
    if (openNow && place.isOpenNow != true) return false;
    if (open24Hours && place.isOpen24Hours != true) return false;
    if (evConnectorType != null &&
        !place.evConnectorTypes.contains(evConnectorType)) {
      return false;
    }
    if (fuelType != null && !place.fuelTypes.contains(fuelType)) return false;
    if (freeParking && !place.isFreeParking) return false;
    if (paidParking && !place.isPaidParking) return false;
    if (accessible && !place.isAccessible) return false;
    if (familyFriendly && !place.isFamilyFriendly) return false;
    if (place.distanceKm != null && place.distanceKm! > maxDistanceKm) {
      return false;
    }
    return true;
  }
}
