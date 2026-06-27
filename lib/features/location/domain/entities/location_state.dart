import 'package:rihla/features/location/domain/entities/gps_service_status.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/errors/location_failure.dart';

/// Aggregate state of the location subsystem.
sealed class LocationState {
  const LocationState();
}

/// Location is idle — no active request or stream.
final class LocationIdle extends LocationState {
  const LocationIdle({
    this.permissionStatus = LocationPermissionStatus.unknown,
    this.gpsStatus = GpsServiceStatus.unknown,
  });

  final LocationPermissionStatus permissionStatus;
  final GpsServiceStatus gpsStatus;
}

/// A location request or stream is in progress.
final class LocationLoading extends LocationState {
  const LocationLoading({
    required this.permissionStatus,
    required this.gpsStatus,
  });

  final LocationPermissionStatus permissionStatus;
  final GpsServiceStatus gpsStatus;
}

/// A position fix is available.
final class LocationActive extends LocationState {
  const LocationActive({
    required this.position,
    required this.permissionStatus,
    required this.gpsStatus,
    this.isStreaming = false,
  });

  final LocationPosition position;
  final LocationPermissionStatus permissionStatus;
  final GpsServiceStatus gpsStatus;
  final bool isStreaming;

  LocationActive copyWith({
    LocationPosition? position,
    LocationPermissionStatus? permissionStatus,
    GpsServiceStatus? gpsStatus,
    bool? isStreaming,
  }) {
    return LocationActive(
      position: position ?? this.position,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

/// Location could not be obtained.
final class LocationError extends LocationState {
  const LocationError({
    required this.failure,
    required this.permissionStatus,
    required this.gpsStatus,
    this.lastKnownPosition,
  });

  final LocationFailure failure;
  final LocationPermissionStatus permissionStatus;
  final GpsServiceStatus gpsStatus;
  final LocationPosition? lastKnownPosition;
}
