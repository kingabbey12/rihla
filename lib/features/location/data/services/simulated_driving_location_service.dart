import 'dart:async';
import 'dart:math' as math;

import 'package:rihla/features/location/domain/entities/gps_service_status.dart';
import 'package:rihla/features/location/domain/entities/location_accuracy.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/services/location_service.dart';

/// A [LocationService] that fakes a moving GPS by driving a vehicle along a
/// looped route. Used on platforms without real GPS (e.g. macOS desktop) so the
/// map shows a live, moving location marker — "pretend you are driving".
///
/// Permission and GPS always report as available so the location pipeline runs
/// exactly as it would on a real device.
class SimulatedDrivingLocationService implements LocationService {
  SimulatedDrivingLocationService({
    List<({double lat, double lng})>? route,
    this.updateInterval = const Duration(milliseconds: 1000),
    this.speedMetersPerSecond = 16, // ~58 km/h city driving
    this.isDriving,
  }) : _route = route ?? _defaultDubaiRoute;

  /// Ordered waypoints the simulated vehicle drives through, looping at the end.
  final List<({double lat, double lng})> _route;

  /// Whether the simulated vehicle should currently be moving. When this returns
  /// false (the default-null case treats it as always driving) the marker stays
  /// parked instead of gliding around on its own — so it only moves once the
  /// user actually starts a journey, not while they are standing still.
  final bool Function()? isDriving;

  /// How often a new position is emitted.
  final Duration updateInterval;

  /// Cruising speed used to advance along the route between waypoints.
  final double speedMetersPerSecond;

  /// A loop around Dubai Marina / JBR / Sheikh Zayed Road.
  static const List<({double lat, double lng})> _defaultDubaiRoute = [
    (lat: 25.0805, lng: 55.1403),
    (lat: 25.0762, lng: 55.1340),
    (lat: 25.0721, lng: 55.1310),
    (lat: 25.0689, lng: 55.1389),
    (lat: 25.0741, lng: 55.1446),
    (lat: 25.0808, lng: 55.1472),
    (lat: 25.0856, lng: 55.1452),
    (lat: 25.0833, lng: 55.1402),
  ];

  @override
  Future<LocationPermissionStatus> checkPermission() async =>
      LocationPermissionStatus.granted;

  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      LocationPermissionStatus.granted;

  @override
  Future<GpsServiceStatus> getGpsStatus() async => GpsServiceStatus.enabled;

  @override
  Future<LocationPosition> getCurrentPosition({
    required LocationAccuracyLevel accuracy,
    Duration? timeout,
  }) async {
    final start = _route.first;
    final next = _route[1 % _route.length];
    return LocationPosition(
      latitude: start.lat,
      longitude: start.lng,
      accuracy: 5,
      timestamp: DateTime.now(),
      speed: speedMetersPerSecond,
      heading: _bearing(start.lat, start.lng, next.lat, next.lng),
    );
  }

  @override
  Stream<LocationPosition> getPositionStream({
    required LocationAccuracyLevel accuracy,
    int distanceFilterMeters = 10,
  }) async* {
    var segment = 0;
    var t = 0.0; // progress [0,1] within the current segment

    while (true) {
      await Future<void>.delayed(updateInterval);

      final driving = isDriving?.call() ?? true;

      // Only advance along the route while actively driving. When parked the
      // marker holds its current position so it never wanders on its own.
      if (driving) {
        final from = _route[segment % _route.length];
        final to = _route[(segment + 1) % _route.length];
        final segmentMeters =
            _distanceMeters(from.lat, from.lng, to.lat, to.lng);
        final stepMeters = speedMetersPerSecond *
            (updateInterval.inMilliseconds / 1000);
        final stepFraction =
            segmentMeters == 0 ? 1.0 : stepMeters / segmentMeters;

        t += stepFraction;
        while (t >= 1.0) {
          t -= 1.0;
          segment = (segment + 1) % _route.length;
        }
      }

      final a = _route[segment % _route.length];
      final b = _route[(segment + 1) % _route.length];
      final lat = a.lat + (b.lat - a.lat) * t;
      final lng = a.lng + (b.lng - a.lng) * t;

      yield LocationPosition(
        latitude: lat,
        longitude: lng,
        accuracy: 5,
        timestamp: DateTime.now(),
        speed: driving ? speedMetersPerSecond : 0,
        heading: _bearing(a.lat, a.lng, b.lat, b.lng),
      );
    }
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  static double _distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _bearing(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLng = _toRad(lng2 - lng1);
    final y = math.sin(dLng) * math.cos(_toRad(lat2));
    final x = math.cos(_toRad(lat1)) * math.sin(_toRad(lat2)) -
        math.sin(_toRad(lat1)) * math.cos(_toRad(lat2)) * math.cos(dLng);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
