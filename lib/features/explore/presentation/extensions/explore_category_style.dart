import 'package:flutter/material.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';

/// Presentation-only visual styling for Explore categories: icon, gradient,
/// and a short tile label. Pure UI metadata — no domain/backend changes.
extension ExploreCategoryStyle on ExploreCategory {
  IconData get glyph => switch (this) {
        ExploreCategory.fuelStation => Icons.local_gas_station_rounded,
        ExploreCategory.evCharger => Icons.ev_station_rounded,
        ExploreCategory.restaurant => Icons.restaurant_rounded,
        ExploreCategory.coffeeShop => Icons.local_cafe_rounded,
        ExploreCategory.hotel => Icons.hotel_rounded,
        ExploreCategory.hospital => Icons.local_hospital_rounded,
        ExploreCategory.pharmacy => Icons.local_pharmacy_rounded,
        ExploreCategory.policeStation => Icons.local_police_rounded,
        ExploreCategory.restroom => Icons.wc_rounded,
        ExploreCategory.parking => Icons.local_parking_rounded,
        ExploreCategory.mosque => Icons.mosque_rounded,
        ExploreCategory.atm => Icons.atm_rounded,
        ExploreCategory.carWash => Icons.local_car_wash_rounded,
        ExploreCategory.shoppingMall => Icons.shopping_bag_rounded,
        ExploreCategory.supermarket => Icons.storefront_rounded,
        ExploreCategory.touristAttraction => Icons.attractions_rounded,
      };

  /// Short tile label (more compact than [displayName]).
  String get shortLabel => switch (this) {
        ExploreCategory.fuelStation => 'Fuel',
        ExploreCategory.evCharger => 'EV Charging',
        ExploreCategory.restaurant => 'Restaurants',
        ExploreCategory.coffeeShop => 'Coffee',
        ExploreCategory.hotel => 'Hotels',
        ExploreCategory.hospital => 'Hospitals',
        ExploreCategory.pharmacy => 'Pharmacies',
        ExploreCategory.policeStation => 'Police',
        ExploreCategory.restroom => 'Restrooms',
        ExploreCategory.parking => 'Parking',
        ExploreCategory.mosque => 'Mosques',
        ExploreCategory.atm => 'ATMs',
        ExploreCategory.carWash => 'Car Wash',
        ExploreCategory.shoppingMall => 'Shopping',
        ExploreCategory.supermarket => 'Supermarkets',
        ExploreCategory.touristAttraction => 'Attractions',
      };

  /// Two-stop gradient used for category cards and marker accents.
  List<Color> get gradient => switch (this) {
        ExploreCategory.fuelStation =>
          const [Color(0xFFFF7043), Color(0xFFF4511E)],
        ExploreCategory.evCharger =>
          const [Color(0xFF26C281), Color(0xFF159947)],
        ExploreCategory.restaurant =>
          const [Color(0xFFFF6B6B), Color(0xFFE53935)],
        ExploreCategory.coffeeShop =>
          const [Color(0xFFA1764E), Color(0xFF6D4C36)],
        ExploreCategory.hotel => const [Color(0xFF5C6BC0), Color(0xFF3949AB)],
        ExploreCategory.hospital =>
          const [Color(0xFFEF5350), Color(0xFFC62828)],
        ExploreCategory.pharmacy =>
          const [Color(0xFF26A69A), Color(0xFF00796B)],
        ExploreCategory.policeStation =>
          const [Color(0xFF42A5F5), Color(0xFF1565C0)],
        ExploreCategory.restroom =>
          const [Color(0xFF78909C), Color(0xFF455A64)],
        ExploreCategory.parking => const [Color(0xFF5C6BC0), Color(0xFF283593)],
        ExploreCategory.mosque => const [Color(0xFF0D7C7C), Color(0xFF094949)],
        ExploreCategory.atm => const [Color(0xFF66BB6A), Color(0xFF2E7D32)],
        ExploreCategory.carWash => const [Color(0xFF29B6F6), Color(0xFF0277BD)],
        ExploreCategory.shoppingMall =>
          const [Color(0xFFEC407A), Color(0xFFAD1457)],
        ExploreCategory.supermarket =>
          const [Color(0xFFFFA726), Color(0xFFEF6C00)],
        ExploreCategory.touristAttraction =>
          const [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
      };

  Color get accent => gradient.last;
}
