import 'package:rihla/features/location/domain/entities/gps_service_status.dart';
import 'package:rihla/features/location/domain/entities/location_accuracy.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/services/location_service.dart';

/// Test double for [LocationService].
class FakeLocationService implements LocationService {
  LocationPermissionStatus permissionStatus =
      LocationPermissionStatus.granted;
  GpsServiceStatus gpsStatus = GpsServiceStatus.enabled;
  LocationPosition? currentPosition;
  Object? throwOnGetCurrent;
  Stream<LocationPosition>? stream;
  bool appSettingsOpened = false;
  bool locationSettingsOpened = false;

  @override
  Future<LocationPermissionStatus> checkPermission() async => permissionStatus;

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    permissionStatus = LocationPermissionStatus.granted;
    return permissionStatus;
  }

  @override
  Future<GpsServiceStatus> getGpsStatus() async => gpsStatus;

  @override
  Future<LocationPosition> getCurrentPosition({
    required LocationAccuracyLevel accuracy,
    Duration? timeout,
  }) async {
    if (throwOnGetCurrent != null) throw throwOnGetCurrent!;
    if (currentPosition == null) {
      throw Exception('Location unavailable');
    }
    return currentPosition!;
  }

  @override
  Stream<LocationPosition> getPositionStream({
    required LocationAccuracyLevel accuracy,
    int distanceFilterMeters = 10,
  }) {
    return stream ?? const Stream.empty();
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened = true;
    return true;
  }
}

/// Sample position for tests.
LocationPosition samplePosition({
  double latitude = 25.2048,
  double longitude = 55.2708,
  double accuracy = 5.0,
}) {
  return LocationPosition(
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    timestamp: DateTime.utc(2026, 6, 27, 12),
    altitude: 10,
    speed: 12.5,
    heading: 90,
  );
}
