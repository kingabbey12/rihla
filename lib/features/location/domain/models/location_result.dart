import 'package:rihla/features/location/domain/errors/location_failure.dart';

/// Result wrapper for location operations.
sealed class LocationResult<T> {
  const LocationResult();
}

final class LocationOk<T> extends LocationResult<T> {
  const LocationOk(this.value);

  final T value;
}

final class LocationErr<T> extends LocationResult<T> {
  const LocationErr(this.failure);

  final LocationFailure failure;
}
