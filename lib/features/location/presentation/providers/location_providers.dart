import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/location/data/datasources/geolocator_location_service.dart';
import 'package:rihla/features/location/data/repositories/location_repository_impl.dart';
import 'package:rihla/features/location/data/services/simulated_driving_location_service.dart';
import 'package:rihla/features/location/data/services/unimplemented_background_location_service.dart';
import 'package:rihla/features/map/presentation/map_platform_support.dart';
import 'package:rihla/features/location/domain/entities/gps_service_status.dart';
import 'package:rihla/features/location/domain/entities/location_accuracy.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/domain/models/location_result.dart';
import 'package:rihla/features/location/domain/repositories/location_repository.dart';
import 'package:rihla/features/location/domain/services/background_location_service.dart';
import 'package:rihla/features/location/domain/services/location_service.dart';

/// Provides the platform [LocationService] implementation.
///
/// On platforms with no real GPS / native map engine (e.g. macOS desktop) we
/// use a simulated "driving" location so the map shows a live, moving marker.
/// Real devices (Android/iOS) use the geolocator-backed service.
final locationServiceProvider = Provider<LocationService>(
  (ref) => MapPlatformSupport.supportsNativeMap
      ? GeolocatorLocationService()
      : SimulatedDrivingLocationService(),
);

/// Provides the [LocationRepository] facade.
final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => LocationRepositoryImpl(ref.watch(locationServiceProvider)),
);

/// Placeholder for future background location service.
final backgroundLocationServiceProvider = Provider<BackgroundLocationService>(
  (ref) => UnimplementedBackgroundLocationService(),
);

/// Selected accuracy for location requests.
final locationAccuracyProvider =
    NotifierProvider<LocationAccuracyNotifier, LocationAccuracyLevel>(
  LocationAccuracyNotifier.new,
);

class LocationAccuracyNotifier extends Notifier<LocationAccuracyLevel> {
  @override
  LocationAccuracyLevel build() => LocationAccuracyLevel.high;

  void setAccuracy(LocationAccuracyLevel accuracy) => state = accuracy;
}

/// Current permission status.
final locationPermissionStatusProvider =
    FutureProvider<LocationPermissionStatus>((ref) {
  return ref.watch(locationRepositoryProvider).getPermissionStatus();
});

/// Current GPS / location services status.
final gpsServiceStatusProvider = FutureProvider<GpsServiceStatus>((ref) {
  return ref.watch(locationRepositoryProvider).getGpsStatus();
});

/// Manages foreground location state (single fix + stream).
final locationControllerProvider =
    NotifierProvider<LocationController, LocationState>(
  LocationController.new,
);

class LocationController extends Notifier<LocationState> {
  LocationRepository get _repository => ref.read(locationRepositoryProvider);
  StreamSubscription<LocationResult<LocationPosition>>? _subscription;

  @override
  LocationState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const LocationIdle();
  }

  Future<void> refreshStatus() async {
    final permission = await _repository.getPermissionStatus();
    final gps = await _repository.getGpsStatus();
    state = LocationIdle(permissionStatus: permission, gpsStatus: gps);
  }

  Future<void> requestPermission() async {
    final permission = await _repository.requestPermission();
    final gps = await _repository.getGpsStatus();
    state = LocationIdle(permissionStatus: permission, gpsStatus: gps);
  }

  Future<void> fetchCurrentPosition() async {
    final permission = await _repository.getPermissionStatus();
    final gps = await _repository.getGpsStatus();
    state = LocationLoading(permissionStatus: permission, gpsStatus: gps);

    final accuracy = ref.read(locationAccuracyProvider);
    final result = await _repository.getCurrentPosition(accuracy: accuracy);

    state = switch (result) {
      LocationOk(:final value) => LocationActive(
          position: value,
          permissionStatus: permission,
          gpsStatus: gps,
        ),
      LocationErr(:final failure) => LocationError(
          failure: failure,
          permissionStatus: permission,
          gpsStatus: gps,
        ),
    };
  }

  Future<void> startForegroundStream() async {
    await _subscription?.cancel();

    final permission = await _repository.getPermissionStatus();
    final gps = await _repository.getGpsStatus();
    state = LocationLoading(permissionStatus: permission, gpsStatus: gps);

    final accuracy = ref.read(locationAccuracyProvider);
    _subscription = _repository.watchPosition(accuracy: accuracy).listen(
      (result) {
        switch (result) {
          case LocationOk(:final value):
            state = LocationActive(
              position: value,
              permissionStatus: permission,
              gpsStatus: gps,
              isStreaming: true,
            );
          case LocationErr(:final failure):
            final lastPosition = switch (state) {
              LocationActive(:final position) => position,
              LocationError(:final lastKnownPosition) => lastKnownPosition,
              _ => null,
            };
            state = LocationError(
              failure: failure,
              permissionStatus: permission,
              gpsStatus: gps,
              lastKnownPosition: lastPosition,
            );
        }
      },
    );
  }

  Future<void> stopStream() async {
    await _subscription?.cancel();
    _subscription = null;

    final current = state;
    if (current is LocationActive) {
      state = LocationIdle(
        permissionStatus: current.permissionStatus,
        gpsStatus: current.gpsStatus,
      );
    }
  }
}
