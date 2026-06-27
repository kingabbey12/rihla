import 'package:rihla/features/location/domain/entities/location_accuracy.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/services/background_location_service.dart';

/// Placeholder for future background location implementation.
///
/// Throws [UnimplementedError] until a background phase wires up
/// platform-specific background tracking.
class UnimplementedBackgroundLocationService implements BackgroundLocationService {
  @override
  bool get isRunning => false;

  @override
  Stream<LocationPosition> get positionStream =>
      const Stream<LocationPosition>.empty();

  @override
  Future<void> start({
    required LocationAccuracyLevel accuracy,
    int distanceFilterMeters = 25,
  }) {
    throw UnimplementedError(
      'Background location updates will be implemented in a future phase.',
    );
  }

  @override
  Future<void> stop() async {}
}
