/// Geographic endpoint for a journey (origin or destination).
class JourneyEndpoint {
  const JourneyEndpoint({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.id,
  });

  final String? id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyEndpoint &&
          id == other.id &&
          name == other.name &&
          address == other.address &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      Object.hash(id, name, address, latitude, longitude);
}
