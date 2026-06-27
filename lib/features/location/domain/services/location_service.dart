import 'package:rihla/features/location/domain/entities/gps_service_status.dart';
import 'package:rihla/features/location/domain/entities/location_accuracy.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';

/// Low-level contract for platform location operations.
abstract class LocationService {
  Future<LocationPermissionStatus> checkPermission();

  Future<LocationPermissionStatus> requestPermission();

  Future<GpsServiceStatus> getGpsStatus();

  Future<LocationPosition> getCurrentPosition({
    required LocationAccuracyLevel accuracy,
    Duration? timeout,
  });

  Stream<LocationPosition> getPositionStream({
    required LocationAccuracyLevel accuracy,
    int distanceFilterMeters = 10,
  });

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}
