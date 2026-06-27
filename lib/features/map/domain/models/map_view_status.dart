import 'package:rihla/features/map/domain/errors/map_failure.dart';

/// Lifecycle status of the map view.
sealed class MapViewStatus {
  const MapViewStatus();
}

/// The map engine is initializing (style loading).
final class MapInitializing extends MapViewStatus {
  const MapInitializing();
}

/// The map is loaded and interactive.
final class MapReady extends MapViewStatus {
  const MapReady();
}

/// The map failed to load.
final class MapErrored extends MapViewStatus {
  const MapErrored(this.failure);

  final MapFailure failure;
}

/// The map loaded but no user location is available.
final class MapLocationEmpty extends MapViewStatus {
  const MapLocationEmpty();
}
