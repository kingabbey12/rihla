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
  MapCamera build() => MapCamera.initial;

  void update(MapCamera camera) => state = camera;
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
