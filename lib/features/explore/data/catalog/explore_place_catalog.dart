import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

/// Seed catalog of UAE discoverable places for online Explore.
abstract final class ExplorePlaceCatalog {
  static List<ExplorePlace> allPlaces() => [
        ..._seedCategory(ExploreCategory.fuelStation, 'ENOC', 25.20, 55.27, 6),
        ..._seedCategory(ExploreCategory.evCharger, 'ChargePoint', 25.18, 55.25, 5),
        ..._seedCategory(ExploreCategory.restaurant, 'Restaurant', 25.19, 55.28, 8),
        ..._seedCategory(ExploreCategory.coffeeShop, 'Coffee House', 25.21, 55.26, 6),
        ..._seedCategory(ExploreCategory.hotel, 'Hotel', 25.22, 55.29, 5),
        ..._seedCategory(ExploreCategory.hospital, 'Hospital', 25.17, 55.30, 4),
        ..._seedCategory(ExploreCategory.pharmacy, 'Pharmacy', 25.20, 55.24, 4),
        ..._seedCategory(ExploreCategory.policeStation, 'Police Station', 25.16, 55.27, 3),
        ..._seedCategory(ExploreCategory.restroom, 'Public Restroom', 25.19, 55.25, 4),
        ..._seedCategory(ExploreCategory.parking, 'Parking', 25.21, 55.28, 6),
        ..._seedCategory(ExploreCategory.mosque, 'Mosque', 25.18, 55.29, 5),
        ..._seedCategory(ExploreCategory.atm, 'ATM', 25.20, 55.26, 5),
        ..._seedCategory(ExploreCategory.carWash, 'Car Wash', 25.15, 55.28, 3),
        ..._seedCategory(ExploreCategory.shoppingMall, 'Mall', 25.197, 55.279, 4),
        ..._seedCategory(ExploreCategory.supermarket, 'Supermarket', 25.19, 55.27, 5),
        ..._seedCategory(
          ExploreCategory.touristAttraction,
          'Attraction',
          25.197,
          55.274,
          5,
        ),
        ..._seedCategory(ExploreCategory.fuelStation, 'ADNOC', 24.49, 54.37, 4),
        ..._seedCategory(ExploreCategory.evCharger, 'DEWA EV', 24.48, 54.36, 3),
        ..._seedCategory(ExploreCategory.restaurant, 'Abu Dhabi Restaurant', 24.47, 54.35, 4),
        ..._seedCategory(ExploreCategory.hotel, 'Abu Dhabi Hotel', 24.50, 54.38, 3),
      ];

  static ExplorePlace fromSearchPlace(SearchPlace place) {
    final category = _categoryFromSearchKey(place.category);
    return ExplorePlace(
      id: place.id,
      name: place.name,
      category: category,
      latitude: place.latitude,
      longitude: place.longitude,
      address: place.address,
      rating: 4.0,
      isOpenNow: true,
      openingHours: '24 hours',
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

  static List<ExplorePlace> _seedCategory(
    ExploreCategory category,
    String namePrefix,
    double baseLat,
    double baseLng,
    int count,
  ) {
    return List.generate(count, (i) {
      final lat = baseLat + (i * 0.012) - 0.02;
      final lng = baseLng + (i * 0.008) - 0.015;
      return ExplorePlace(
        id: 'explore_${category.name}_$i',
        name: '$namePrefix ${i + 1}',
        category: category,
        latitude: lat,
        longitude: lng,
        address: '$namePrefix Street, UAE',
        rating: 3.5 + (i % 3) * 0.5,
        reviewCount: 20 + i * 15,
        openingHours: i.isEven ? '06:00 – 23:00' : '24 hours',
        isOpenNow: i % 4 != 0,
        isOpen24Hours: i.isOdd,
        phone: '+971 4 ${100 + i} ${2000 + i}',
        website: 'https://example.com/${category.name}/$i',
        photoUrl: 'https://picsum.photos/seed/${category.name}$i/400/300',
        fuelTypes: category == ExploreCategory.fuelStation
            ? const ['Petrol 95', 'Petrol 98', 'Diesel']
            : const [],
        evConnectorTypes: category == ExploreCategory.evCharger
            ? const ['CCS', 'Type 2']
            : const [],
        isFreeParking: category == ExploreCategory.parking && i.isEven,
        isPaidParking: category == ExploreCategory.parking,
        isAccessible: i % 2 == 0,
        isFamilyFriendly: category == ExploreCategory.restaurant ||
            category == ExploreCategory.coffeeShop ||
            category == ExploreCategory.shoppingMall,
        priceLevel: 1 + (i % 3),
      );
    });
  }
}
