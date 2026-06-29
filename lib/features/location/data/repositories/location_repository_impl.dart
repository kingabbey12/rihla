import 'package:rihla/features/location/domain/entities/gps_service_status.dart';
import 'package:rihla/features/location/domain/entities/location_accuracy.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/errors/location_failure.dart';
import 'package:rihla/features/location/domain/models/location_result.dart';
import 'package:rihla/features/location/domain/repositories/location_repository.dart';
import 'package:rihla/features/location/domain/services/location_service.dart';

/// Validates permissions and GPS before delegating to [LocationService].
class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._service);

  final LocationService _service;

  @override
  Future<LocationPermissionStatus> getPermissionStatus() =>
      _service.checkPermission();

  @override
  Future<LocationPermissionStatus> requestPermission() =>
      _service.requestPermission();

  @override
  Future<GpsServiceStatus> getGpsStatus() => _service.getGpsStatus();

  @override
  Future<LocationResult<LocationPosition>> getCurrentPosition({
    LocationAccuracyLevel accuracy = LocationAccuracyLevel.bestForNavigation,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final failure = await _validatePreconditions();
    if (failure != null) return LocationErr(failure);

    try {
      final position = await _service.getCurrentPosition(
        accuracy: accuracy,
        timeout: timeout,
      );
      return LocationOk(position);
    } on Object catch (error) {
      return LocationErr(_mapError(error));
    }
  }

  @override
  Stream<LocationResult<LocationPosition>> watchPosition({
    LocationAccuracyLevel accuracy = LocationAccuracyLevel.bestForNavigation,
    int distanceFilterMeters = 5,
  }) async* {
    final failure = await _validatePreconditions();
    if (failure != null) {
      yield LocationErr(failure);
      return;
    }

    try {
      await for (final position in _service.getPositionStream(
        accuracy: accuracy,
        distanceFilterMeters: distanceFilterMeters,
      )) {
        yield LocationOk(position);
      }
    } on Object catch (error) {
      yield LocationErr(_mapError(error));
    }
  }

  @override
  Future<bool> openAppSettings() => _service.openAppSettings();

  @override
  Future<bool> openLocationSettings() => _service.openLocationSettings();

  Future<LocationFailure?> _validatePreconditions() async {
    final permission = await _service.checkPermission();
    final permissionFailure = _permissionFailure(permission);
    if (permissionFailure != null) return permissionFailure;

    final gps = await _service.getGpsStatus();
    if (gps == GpsServiceStatus.disabled) {
      return const LocationGpsDisabled();
    }

    return null;
  }

  LocationFailure? _permissionFailure(LocationPermissionStatus status) {
    return switch (status) {
      LocationPermissionStatus.granted => null,
      LocationPermissionStatus.denied => const LocationPermissionDenied(),
      LocationPermissionStatus.permanentlyDenied =>
        const LocationPermissionPermanentlyDenied(),
      LocationPermissionStatus.unknown => const LocationUnavailable(),
    };
  }

  LocationFailure _mapError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('timeout') ||
        message.contains('timed out') ||
        message.contains('time limit')) {
      return const LocationTimeout();
    }
    if (message.contains('permission')) {
      return const LocationPermissionDenied();
    }
    if (message.contains('disabled') || message.contains('service')) {
      return const LocationGpsDisabled();
    }
    return LocationUnknown(error.toString());
  }
}
