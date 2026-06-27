/// Immutable domain model for a geographic position fix.
class LocationPosition {
  const LocationPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.altitude,
    this.speed,
    this.heading,
  });

  final double latitude;
  final double longitude;

  /// Horizontal accuracy in meters.
  final double accuracy;
  final DateTime timestamp;
  final double? altitude;

  /// Speed in meters per second.
  final double? speed;

  /// Heading in degrees (0–360).
  final double? heading;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPosition &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          accuracy == other.accuracy &&
          timestamp == other.timestamp &&
          altitude == other.altitude &&
          speed == other.speed &&
          heading == other.heading;

  @override
  int get hashCode => Object.hash(
        latitude,
        longitude,
        accuracy,
        timestamp,
        altitude,
        speed,
        heading,
      );

  @override
  String toString() =>
      'LocationPosition(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
}
