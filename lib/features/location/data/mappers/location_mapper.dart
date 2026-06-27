import 'package:geolocator/geolocator.dart' as geo;
import 'package:rihla/features/location/domain/entities/gps_service_status.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/errors/location_failure.dart';

LocationPermissionStatus mapPermission(geo.LocationPermission permission) {
  return switch (permission) {
    geo.LocationPermission.always ||
    geo.LocationPermission.whileInUse =>
      LocationPermissionStatus.granted,
    geo.LocationPermission.denied => LocationPermissionStatus.denied,
    geo.LocationPermission.deniedForever =>
      LocationPermissionStatus.permanentlyDenied,
    geo.LocationPermission.unableToDetermine =>
      LocationPermissionStatus.unknown,
  };
}

GpsServiceStatus mapGpsEnabled(bool enabled) {
  return enabled ? GpsServiceStatus.enabled : GpsServiceStatus.disabled;
}

LocationPosition mapPosition(geo.Position position) {
  return LocationPosition(
    latitude: position.latitude,
    longitude: position.longitude,
    accuracy: position.accuracy,
    timestamp: position.timestamp,
    altitude: position.altitude,
    speed: position.speed,
    heading: position.heading,
  );
}

LocationFailure mapException(Object error) {
  if (error is geo.LocationServiceDisabledException) {
    return const LocationGpsDisabled();
  }
  if (error is geo.PermissionDeniedException) {
    return const LocationPermissionDenied();
  }
  if (error is geo.PositionUpdateException) {
    return const LocationUnavailable();
  }
  final description = error.toString().toLowerCase();
  if (description.contains('timeout') || description.contains('time limit')) {
    return const LocationTimeout();
  }
  return LocationUnknown(error.toString());
}
