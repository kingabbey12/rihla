/// A fuel station with current price information.
class FuelStation {
  const FuelStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.fuelType,
    required this.pricePerLiter,
    required this.currency,
    required this.distanceKm,
    this.isOpen = true,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String fuelType;
  final double pricePerLiter;
  final String currency;
  final double distanceKm;
  final bool isOpen;
}
