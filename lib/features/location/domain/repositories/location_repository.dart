import 'package:rihla/features/location/domain/entities/gps_service_status.dart';
import 'package:rihla/features/location/domain/entities/location_accuracy.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/models/location_result.dart';

/// High-level location operations with permission and GPS validation.
abstract class LocationRepository {
  Future<LocationPermissionStatus> getPermissionStatus();

  Future<LocationPermissionStatus> requestPermission();

  Future<GpsServiceStatus> getGpsStatus();

  Future<LocationResult<LocationPosition>> getCurrentPosition({
    LocationAccuracyLevel accuracy = LocationAccuracyLevel.bestForNavigation,
    Duration timeout = const Duration(seconds: 15),
  });

  Stream<LocationResult<LocationPosition>> watchPosition({
    LocationAccuracyLevel accuracy = LocationAccuracyLevel.bestForNavigation,
    int distanceFilterMeters = 5,
  });

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}
