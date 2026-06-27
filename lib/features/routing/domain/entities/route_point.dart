/// A geographic point used in route requests.
class RoutePoint {
  const RoutePoint({
    required this.latitude,
    required this.longitude,
    this.name,
    this.id,
  });

  final double latitude;
  final double longitude;
  final String? name;
  final String? id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutePoint &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          name == other.name &&
          id == other.id;

  @override
  int get hashCode => Object.hash(latitude, longitude, name, id);
}
