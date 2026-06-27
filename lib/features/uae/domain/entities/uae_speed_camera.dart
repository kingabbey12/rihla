/// UAE speed enforcement camera types.
enum UaeCameraType {
  fixed,
  averageSpeed,
  redLight,
  schoolZone,
}

/// Speed camera location for advisory alerts.
class UaeSpeedCamera {
  const UaeSpeedCamera({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.speedLimitKmh,
    this.zoneLengthKm,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final UaeCameraType type;
  final int speedLimitKmh;
  final double? zoneLengthKm;
}
