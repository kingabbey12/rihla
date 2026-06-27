import 'package:geolocator/geolocator.dart' as geo;
import 'package:rihla/features/location/data/mappers/location_accuracy_mapper.dart';
import 'package:rihla/features/location/data/mappers/location_mapper.dart';
import 'package:rihla/features/location/domain/entities/gps_service_status.dart';
import 'package:rihla/features/location/domain/entities/location_accuracy.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/services/location_service.dart';

/// Geolocator-backed implementation of [LocationService].
class GeolocatorLocationService implements LocationService {
  GeolocatorLocationService({geo.GeolocatorPlatform? platform})
      : _platform = platform ?? geo.GeolocatorPlatform.instance;

  final geo.GeolocatorPlatform _platform;

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    final permission = await _platform.checkPermission();
    return mapPermission(permission);
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    var permission = await _platform.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await _platform.requestPermission();
    }
    return mapPermission(permission);
  }

  @override
  Future<GpsServiceStatus> getGpsStatus() async {
    final enabled = await _platform.isLocationServiceEnabled();
    return mapGpsEnabled(enabled);
  }

  @override
  Future<LocationPosition> getCurrentPosition({
    required LocationAccuracyLevel accuracy,
    Duration? timeout,
  }) async {
    final position = await _platform.getCurrentPosition(
      locationSettings: geo.LocationSettings(
        accuracy: toGeolocatorAccuracy(accuracy),
        timeLimit: timeout,
      ),
    );
    return mapPosition(position);
  }

  @override
  Stream<LocationPosition> getPositionStream({
    required LocationAccuracyLevel accuracy,
    int distanceFilterMeters = 10,
  }) {
    return _platform
        .getPositionStream(
          locationSettings: geo.LocationSettings(
            accuracy: toGeolocatorAccuracy(accuracy),
            distanceFilter: distanceFilterMeters,
          ),
        )
        .map(mapPosition);
  }

  @override
  Future<bool> openAppSettings() => _platform.openAppSettings();

  @override
  Future<bool> openLocationSettings() => _platform.openLocationSettings();
}
