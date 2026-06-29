import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

/// Converts bundled offline POIs into Explore places.
abstract final class ExplorePlaceCatalog {
  static ExplorePlace fromSearchPlace(SearchPlace place) {
    final category = _categoryFromSearchKey(place.category);
    return ExplorePlace(
      id: place.id,
      name: place.name,
      category: category,
      latitude: place.latitude,
      longitude: place.longitude,
      address: place.address,
    );
  }

  static ExploreCategory _categoryFromSearchKey(String? key) {
    return switch (key) {
      'mall' => ExploreCategory.shoppingMall,
      'airport' => ExploreCategory.touristAttraction,
      'landmark' => ExploreCategory.touristAttraction,
      'fuelStation' => ExploreCategory.fuelStation,
      'evCharger' => ExploreCategory.evCharger,
      'parking' => ExploreCategory.parking,
      _ => ExploreCategory.touristAttraction,
    };
  }
}
