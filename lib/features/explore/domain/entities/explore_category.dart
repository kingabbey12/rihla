/// Discovery categories for the Explore platform.
enum ExploreCategory {
  fuelStation,
  evCharger,
  restaurant,
  coffeeShop,
  hotel,
  hospital,
  pharmacy,
  policeStation,
  restroom,
  parking,
  mosque,
  atm,
  carWash,
  shoppingMall,
  supermarket,
  touristAttraction,
}

extension ExploreCategoryX on ExploreCategory {
  String get id => name;

  String get displayName => switch (this) {
        ExploreCategory.fuelStation => 'Fuel Stations',
        ExploreCategory.evCharger => 'EV Chargers',
        ExploreCategory.restaurant => 'Restaurants',
        ExploreCategory.coffeeShop => 'Coffee Shops',
        ExploreCategory.hotel => 'Hotels',
        ExploreCategory.hospital => 'Hospitals',
        ExploreCategory.pharmacy => 'Pharmacies',
        ExploreCategory.policeStation => 'Police Stations',
        ExploreCategory.restroom => 'Restrooms',
        ExploreCategory.parking => 'Parking',
        ExploreCategory.mosque => 'Mosques',
        ExploreCategory.atm => 'ATMs',
        ExploreCategory.carWash => 'Car Wash',
        ExploreCategory.shoppingMall => 'Shopping Malls',
        ExploreCategory.supermarket => 'Supermarkets',
        ExploreCategory.touristAttraction => 'Tourist Attractions',
      };

  String get iconName => switch (this) {
        ExploreCategory.fuelStation => 'local_gas_station',
        ExploreCategory.evCharger => 'ev_station',
        ExploreCategory.restaurant => 'restaurant',
        ExploreCategory.coffeeShop => 'coffee',
        ExploreCategory.hotel => 'hotel',
        ExploreCategory.hospital => 'local_hospital',
        ExploreCategory.pharmacy => 'local_pharmacy',
        ExploreCategory.policeStation => 'local_police',
        ExploreCategory.restroom => 'wc',
        ExploreCategory.parking => 'local_parking',
        ExploreCategory.mosque => 'mosque',
        ExploreCategory.atm => 'atm',
        ExploreCategory.carWash => 'local_car_wash',
        ExploreCategory.shoppingMall => 'shopping_bag',
        ExploreCategory.supermarket => 'store',
        ExploreCategory.touristAttraction => 'attractions',
      };
}
