import 'package:rihla/features/location/domain/entities/location_accuracy.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';

/// Contract for future background location updates.
///
/// Implementation is deferred to a later phase. Navigation features
/// should depend on this interface rather than calling platform APIs directly.
abstract class BackgroundLocationService {
  bool get isRunning;

  Stream<LocationPosition> get positionStream;

  Future<void> start({
    required LocationAccuracyLevel accuracy,
    int distanceFilterMeters = 25,
  });

  Future<void> stop();
}
