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

  /// Sentinel before the first GPS fix. The map stays in a loading state until
  /// the user's real position resolves — never a fixed city coordinate.
  static const MapCamera pending = MapCamera(
    latitude: 0,
    longitude: 0,
    zoom: 2,
  );

  /// @deprecated Use [pending]. Kept for call-site migration.
  static const MapCamera initial = pending;

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
