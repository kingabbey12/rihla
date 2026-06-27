/// Typed failures for the location subsystem.
sealed class LocationFailure {
  const LocationFailure();

  String get message;
}

final class LocationPermissionDenied extends LocationFailure {
  const LocationPermissionDenied();

  @override
  String get message => 'Location permission was denied.';
}

final class LocationPermissionPermanentlyDenied extends LocationFailure {
  const LocationPermissionPermanentlyDenied();

  @override
  String get message =>
      'Location permission is permanently denied. Enable it in Settings.';
}

final class LocationGpsDisabled extends LocationFailure {
  const LocationGpsDisabled();

  @override
  String get message => 'Location services are disabled on this device.';
}

final class LocationUnavailable extends LocationFailure {
  const LocationUnavailable();

  @override
  String get message => 'Location is currently unavailable.';
}

final class LocationTimeout extends LocationFailure {
  const LocationTimeout();

  @override
  String get message => 'Location request timed out.';
}

final class LocationUnknown extends LocationFailure {
  const LocationUnknown([this.detail]);

  final String? detail;

  @override
  String get message => detail ?? 'An unknown location error occurred.';
}
