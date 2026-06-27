/// Typed failures for the map subsystem.
sealed class MapFailure {
  const MapFailure();

  String get message;
}

/// The map style or engine failed to initialize.
final class MapInitializationFailure extends MapFailure {
  const MapInitializationFailure([this.detail]);

  final String? detail;

  @override
  String get message => detail ?? 'The map failed to load.';
}

/// The map could not resolve a usable location.
final class MapLocationUnavailableFailure extends MapFailure {
  const MapLocationUnavailableFailure();

  @override
  String get message => 'Your location is currently unavailable.';
}
