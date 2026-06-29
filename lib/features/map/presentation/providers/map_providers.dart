import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/map/domain/entities/map_camera.dart';
import 'package:rihla/features/map/domain/entities/map_style_variant.dart';
import 'package:rihla/features/map/domain/models/map_view_status.dart';

/// Maps a [Brightness] to the corresponding [MapStyleVariant].
MapStyleVariant styleVariantForBrightness(Brightness brightness) =>
    brightness == Brightness.dark
        ? MapStyleVariant.dark
        : MapStyleVariant.light;

/// Active map style variant. Synced to app theme by the map view.
final mapStyleVariantProvider =
    NotifierProvider<MapStyleVariantNotifier, MapStyleVariant>(
  MapStyleVariantNotifier.new,
);

class MapStyleVariantNotifier extends Notifier<MapStyleVariant> {
  @override
  MapStyleVariant build() => MapStyleVariant.light;

  void setVariant(MapStyleVariant variant) {
    if (state != variant) state = variant;
  }
}

/// Latest known camera position. Updated when the camera settles.
final mapCameraProvider =
    NotifierProvider<MapCameraNotifier, MapCamera>(MapCameraNotifier.new);

class MapCameraNotifier extends Notifier<MapCamera> {
  @override
  MapCamera build() => MapCamera.pending;

  void update(MapCamera camera) => state = camera;
}

/// True once the map has centered on the user's real GPS fix at least once.
final mapUserLocationResolvedProvider =
    NotifierProvider<MapUserLocationResolvedNotifier, bool>(
  MapUserLocationResolvedNotifier.new,
);

class MapUserLocationResolvedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void resolve() => state = true;
  void reset() => state = false;
}

/// Lifecycle status of the map view.
final mapViewStatusProvider =
    NotifierProvider<MapViewStatusNotifier, MapViewStatus>(
  MapViewStatusNotifier.new,
);

class MapViewStatusNotifier extends Notifier<MapViewStatus> {
  @override
  MapViewStatus build() => const MapInitializing();

  void set(MapViewStatus status) => state = status;
}

/// True when a location request could not resolve a position.
/// Drives the dismissible "location unavailable" empty state.
final mapLocationUnavailableProvider =
    NotifierProvider<MapLocationUnavailableNotifier, bool>(
  MapLocationUnavailableNotifier.new,
);

class MapLocationUnavailableNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void show() => state = true;
  void dismiss() => state = false;
}

/// Incremented to force the native map to be recreated (e.g. on retry).
final mapRecreateProvider =
    NotifierProvider<MapRecreateNotifier, int>(MapRecreateNotifier.new);

class MapRecreateNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

/// Incremented to ask the map view to re-attempt a "go to my location".
final mapLocationRetryProvider =
    NotifierProvider<MapLocationRetryNotifier, int>(
  MapLocationRetryNotifier.new,
);

class MapLocationRetryNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state = state + 1;
}

/// Incremented to ask the map to resume follow-mode and recenter on the user
/// (e.g. double-tap during navigation, or the "recenter" control).
final navigationFollowRecenterProvider =
    NotifierProvider<NavigationFollowRecenterNotifier, int>(
  NavigationFollowRecenterNotifier.new,
);

class NavigationFollowRecenterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state = state + 1;
}

/// Incremented to ask the map to frame the whole active route ("overview").
/// Framing pauses follow-mode until the user recenters.
final navigationOverviewRequestProvider =
    NotifierProvider<NavigationOverviewRequestNotifier, int>(
  NavigationOverviewRequestNotifier.new,
);

class NavigationOverviewRequestNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state = state + 1;
}

/// A one-shot camera fly-to request consumed by [MapView].
final mapFlyToTargetProvider =
    NotifierProvider<MapFlyToTargetNotifier, MapFlyToTarget?>(
  MapFlyToTargetNotifier.new,
);

/// Describes where the map camera should animate to.
class MapFlyToTarget {
  const MapFlyToTarget({
    required this.latitude,
    required this.longitude,
    this.zoom = 15.5,
    required this.sequence,
  });

  final double latitude;
  final double longitude;
  final double zoom;

  /// Monotonic counter so repeated selections to the same coords still fire.
  final int sequence;
}

class MapFlyToTargetNotifier extends Notifier<MapFlyToTarget?> {
  @override
  MapFlyToTarget? build() => null;

  void flyTo({
    required double latitude,
    required double longitude,
    double zoom = 15.5,
  }) {
    state = MapFlyToTarget(
      latitude: latitude,
      longitude: longitude,
      zoom: zoom,
      sequence: DateTime.now().microsecondsSinceEpoch,
    );
  }
}
