/// A parking location with availability and pricing.
class ParkingLocation {
  const ParkingLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.pricePerHour,
    required this.currency,
    required this.isAvailable,
    required this.openingHours,
    this.capacity,
    this.occupiedSpaces,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final double pricePerHour;
  final String currency;
  final bool isAvailable;
  final String openingHours;
  final int? capacity;
  final int? occupiedSpaces;
}
