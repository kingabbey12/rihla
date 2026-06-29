/// Immutable camera position for the map.
class MapCamera {
  const MapCamera({
    required this.latitude,
    required this.longitude,
    required this.zoom,
    this.bearing = 0,
    this.tilt = 0,
  });

  final double latitude;
  final double longitude;
  final double zoom;

  /// Map rotation in degrees (0 = north up).
  final double bearing;

  /// Camera pitch in degrees (0 = top-down).
  final double tilt;

  /// Default camera centered on Dubai when the user's location is not yet
  /// available (e.g. permission not granted). Replaced with the live position
  /// as soon as it resolves.
  static const MapCamera initial = MapCamera(
    latitude: 25.2048,
    longitude: 55.2708,
    zoom: 12,
  );

  MapCamera copyWith({
    double? latitude,
    double? longitude,
    double? zoom,
    double? bearing,
    double? tilt,
  }) {
    return MapCamera(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      zoom: zoom ?? this.zoom,
      bearing: bearing ?? this.bearing,
      tilt: tilt ?? this.tilt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapCamera &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          zoom == other.zoom &&
          bearing == other.bearing &&
          tilt == other.tilt;

  @override
  int get hashCode => Object.hash(latitude, longitude, zoom, bearing, tilt);

  @override
  String toString() =>
      'MapCamera(lat: $latitude, lng: $longitude, zoom: $zoom, '
      'bearing: $bearing, tilt: $tilt)';
}
