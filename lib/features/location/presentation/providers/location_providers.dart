import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/observability/breadcrumb.dart';
import 'package:rihla/core/observability/observability_providers.dart';
import 'package:rihla/features/location/data/datasources/geolocator_location_service.dart';
import 'package:rihla/features/location/data/repositories/location_repository_impl.dart';
import 'package:rihla/features/location/data/services/unimplemented_background_location_service.dart';
import 'package:rihla/features/location/domain/entities/gps_service_status.dart';
import 'package:rihla/features/location/domain/entities/location_accuracy.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/domain/models/location_result.dart';
import 'package:rihla/features/location/domain/repositories/location_repository.dart';
import 'package:rihla/features/location/domain/services/background_location_service.dart';
import 'package:rihla/features/location/domain/services/location_service.dart';

/// Device GPS via Geolocator on every platform (including macOS desktop).
final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
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
  // Navigation-grade accuracy by default: maps to
  // kCLLocationAccuracyBestForNavigation (iOS/macOS) / PRIORITY_HIGH_ACCURACY
  // (Android), the fused GPS+sensor signal needed for correct UAE positioning.
  @override
  LocationAccuracyLevel build() => LocationAccuracyLevel.bestForNavigation;

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

  /// Reject fixes worse than this horizontal accuracy once we already hold a
  /// good fix. A 100 m+ fix is typically a Wi-Fi/IP estimate that can land in
  /// the wrong part of the UAE; the first fix is always accepted to avoid a
  /// blank map.
  static const double _maxAcceptableAccuracyMeters = 100;

  /// Drop fixes whose timestamp is older than the last accepted fix (out of
  /// order / cached replays).
  DateTime? _lastAcceptedAt;

  @override
  LocationState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const LocationIdle();
  }

  void _logFix(LocationPosition p, {required bool accepted, String? reason}) {
    ref.read(appLoggerProvider).log(
      accepted ? 'gps_fix' : 'gps_fix_rejected',
      category: ObservabilityCategory.navigation,
      data: {
        'lat': p.latitude.toStringAsFixed(6),
        'lng': p.longitude.toStringAsFixed(6),
        'acc_m': p.accuracy.toStringAsFixed(1),
        'ts': p.timestamp.toIso8601String(),
        'speed_mps': (p.speed ?? 0).toStringAsFixed(1),
        'heading_deg': (p.heading ?? 0).toStringAsFixed(0),
        'reason': ?reason,
      },
    );
  }

  /// Whether [position] is a fresh, navigation-grade fix worth accepting.
  bool _isAcceptable(LocationPosition position, {required bool haveFix}) {
    // Out-of-order / replayed cached fix.
    final last = _lastAcceptedAt;
    if (last != null && position.timestamp.isBefore(last)) {
      _logFix(position, accepted: false, reason: 'stale_timestamp');
      return false;
    }
    // Low-quality fix once we already have a good position on screen.
    if (haveFix &&
        position.accuracy > 0 &&
        position.accuracy > _maxAcceptableAccuracyMeters) {
      _logFix(position, accepted: false, reason: 'low_accuracy');
      return false;
    }
    return true;
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

    if (result case LocationOk(:final value)) {
      _lastAcceptedAt = value.timestamp;
      _logFix(value, accepted: true);
    }

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
    _subscription = _repository
        .watchPosition(accuracy: accuracy, distanceFilterMeters: 5)
        .listen(
      (result) {
        switch (result) {
          case LocationOk(:final value):
            final haveFix = state is LocationActive;
            if (!_isAcceptable(value, haveFix: haveFix)) return;
            _lastAcceptedAt = value.timestamp;
            _logFix(value, accepted: true);
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
