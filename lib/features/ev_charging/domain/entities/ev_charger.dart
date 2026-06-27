/// An EV charging station.
class EvCharger {
  const EvCharger({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.connectorTypes,
    required this.maxPowerKw,
    required this.isAvailable,
    required this.distanceKm,
    this.operatorName,
    this.chargingSpeed,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> connectorTypes;
  final double maxPowerKw;
  final bool isAvailable;
  final double distanceKm;
  final String? operatorName;
  final String? chargingSpeed;
}
