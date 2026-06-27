import 'dart:async';
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/domain/models/location_result.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/map/data/styles/map_style_catalog.dart';
import 'package:rihla/features/map/domain/entities/map_camera.dart';
import 'package:rihla/features/map/domain/errors/map_failure.dart';
import 'package:rihla/features/map/domain/models/map_view_status.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/explore/domain/entities/explore_marker.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/map/presentation/widgets/map_controls.dart';
import 'package:rihla/features/map/presentation/widgets/map_scale_indicator.dart';

/// Full-screen MapLibre map wrapping the native engine.
///
/// Owns the [MapLibreMapController] and drives camera, style switching, and
/// the floating controls. Overlays (loading/error/empty/debug) live in the
/// parent page so this widget stays focused on the map surface.
class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  static const Duration _initTimeout = Duration(seconds: 20);
  static const double _focusZoom = 15.5;

  MapLibreMapController? _controller;
  Timer? _initTimer;
  late final MapCamera _startCamera;
  Line? _routeLine;
  List<RouteCoordinate>? _pendingPolyline;
  final Map<Circle, ExploreMarker> _exploreCircleMarkers = {};
  Brightness? _lastSyncedBrightness;
  String? _lastMarkerSignature;

  @override
  void initState() {
    super.initState();
    _startCamera = ref.read(mapCameraProvider);
    _startInitTimeout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(locationControllerProvider.notifier).refreshStatus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_lastSyncedBrightness != brightness) {
      _lastSyncedBrightness = brightness;
      final variant = styleVariantForBrightness(brightness);
      ref.read(mapStyleVariantProvider.notifier).setVariant(variant);
    }
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    _controller = null;
    super.dispose();
  }

  void _startInitTimeout() {
    _initTimer?.cancel();
    _initTimer = Timer(_initTimeout, () {
      final status = ref.read(mapViewStatusProvider);
      if (status is MapInitializing) {
        ref.read(mapViewStatusProvider.notifier).set(
              const MapErrored(MapInitializationFailure()),
            );
      }
    });
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onCircleTapped.add(_onExploreCircleTapped);
  }

  void _onExploreCircleTapped(Circle circle) {
    final marker = _exploreCircleMarkers[circle];
    if (marker == null) return;
    if (marker.isCluster) {
      _animate(
        CameraUpdate.newLatLngZoom(
          LatLng(marker.latitude, marker.longitude),
          (ref.read(mapCameraProvider).zoom + 2).clamp(10, 18),
        ),
      );
      return;
    }
    final place = marker.place;
    if (place != null) {
      ref.read(exploreControllerProvider.notifier).selectPlace(place);
    }
  }

  void _onStyleLoaded() {
    _initTimer?.cancel();
    ref.read(mapViewStatusProvider.notifier).set(const MapReady());
    if (_pendingPolyline != null) {
      _renderRouteLine(_pendingPolyline);
    }
    final markers = ref.read(exploreMapMarkersProvider);
    if (markers.isNotEmpty) {
      _renderExploreMarkers(markers);
    }
  }

  Future<void> _renderExploreMarkers(List<ExploreMarker> markers) async {
    final controller = _controller;
    if (controller == null) return;

    // Skip redundant native clear/re-add when the marker set is unchanged.
    final signature = _markerSignature(markers);
    if (signature == _lastMarkerSignature) return;
    _lastMarkerSignature = signature;

    await controller.clearCircles();
    _exploreCircleMarkers.clear();
    if (markers.isEmpty) return;

    final circles = await controller.addCircles(
      markers
          .map(
            (m) => CircleOptions(
              geometry: LatLng(m.latitude, m.longitude),
              circleRadius: m.isCluster ? 14 : 8,
              circleColor: m.isCluster ? '#1B6B6B' : '#0D6E6E',
              circleStrokeWidth: 2,
              circleStrokeColor: '#FFFFFF',
              circleOpacity: 0.92,
            ),
          )
          .toList(),
    );

    for (var i = 0; i < circles.length && i < markers.length; i++) {
      _exploreCircleMarkers[circles[i]] = markers[i];
    }
  }

  /// Compact fingerprint of the marker set used to avoid redundant re-renders.
  static String _markerSignature(List<ExploreMarker> markers) {
    if (markers.isEmpty) return 'empty';
    final buffer = StringBuffer('${markers.length}:');
    for (final m in markers) {
      buffer
        ..write(m.latitude.toStringAsFixed(5))
        ..write(',')
        ..write(m.longitude.toStringAsFixed(5))
        ..write(m.isCluster ? 'c' : 'p')
        ..write(';');
    }
    return buffer.toString();
  }

  Future<void> _renderRouteLine(List<RouteCoordinate>? coords) async {
    _pendingPolyline = coords;
    final controller = _controller;
    if (controller == null || coords == null || coords.isEmpty) {
      if (coords == null && _routeLine != null) {
        await _controller?.removeLine(_routeLine!);
        _routeLine = null;
      }
      return;
    }

    if (_routeLine != null) {
      await controller.removeLine(_routeLine!);
      _routeLine = null;
    }

    _routeLine = await controller.addLine(
      LineOptions(
        geometry: coords
            .map((c) => LatLng(c.latitude, c.longitude))
            .toList(),
        lineColor: '#0D6E6E',
        lineWidth: 5,
        lineOpacity: 0.9,
      ),
    );
  }

  void _onCameraIdle() {
    final position = _controller?.cameraPosition;
    if (position == null) return;
    ref.read(mapCameraProvider.notifier).update(
          MapCamera(
            latitude: position.target.latitude,
            longitude: position.target.longitude,
            zoom: position.zoom,
            bearing: position.bearing,
            tilt: position.tilt,
          ),
        );
  }

  Future<void> _zoomIn() => _animate(CameraUpdate.zoomIn());

  Future<void> _zoomOut() => _animate(CameraUpdate.zoomOut());

  Future<void> _resetOrientation() => _animate(CameraUpdate.bearingTo(0));

  Future<void> _animate(CameraUpdate update) async {
    await _controller?.animateCamera(update);
  }

  Future<void> _flyToTarget(MapFlyToTarget target) async {
    await _animate(
      CameraUpdate.newLatLngZoom(
        LatLng(target.latitude, target.longitude),
        target.zoom,
      ),
    );
    ref.read(mapCameraProvider.notifier).update(
          MapCamera(
            latitude: target.latitude,
            longitude: target.longitude,
            zoom: target.zoom,
          ),
        );
  }

  Future<void> _goToMyLocation() async {
    final repository = ref.read(locationRepositoryProvider);
    final notifier = ref.read(locationControllerProvider.notifier);

    var permission = await repository.getPermissionStatus();
    if (permission != LocationPermissionStatus.granted) {
      permission = await repository.requestPermission();
    }
    await notifier.refreshStatus();

    if (permission != LocationPermissionStatus.granted) {
      ref.read(mapLocationUnavailableProvider.notifier).show();
      return;
    }

    final result = await repository.getCurrentPosition();
    switch (result) {
      case LocationOk(:final value):
        await _animate(
          CameraUpdate.newLatLngZoom(
            LatLng(value.latitude, value.longitude),
            _focusZoom,
          ),
        );
      case LocationErr():
        ref.read(mapLocationUnavailableProvider.notifier).show();
    }
  }

  LocationPermissionStatus _permissionOf(LocationState state) => switch (state) {
        LocationIdle(:final permissionStatus) => permissionStatus,
        LocationLoading(:final permissionStatus) => permissionStatus,
        LocationActive(:final permissionStatus) => permissionStatus,
        LocationError(:final permissionStatus) => permissionStatus,
      };

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final variant = styleVariantForBrightness(brightness);

    final locationState = ref.watch(locationControllerProvider);
    final hasPermission =
        _permissionOf(locationState) == LocationPermissionStatus.granted;
    final camera = ref.watch(mapCameraProvider);

    final recreateKey = ref.watch(mapRecreateProvider);
    ref.listen(mapRecreateProvider, (_, _) => _startInitTimeout());
    ref.listen(mapLocationRetryProvider, (_, _) => _goToMyLocation());
    ref.listen(mapFlyToTargetProvider, (_, next) {
      if (next != null) _flyToTarget(next);
    });
    ref.listen(mapRoutePolylineProvider, (_, next) {
      _renderRouteLine(next);
    });
    ref.listen(exploreMapMarkersProvider, (_, next) {
      _renderExploreMarkers(next);
    });

    return Stack(
      children: [
        Positioned.fill(
          child: MapLibreMap(
            key: ValueKey('maplibre_$recreateKey'),
            styleString: MapStyleCatalog.styleFor(variant),
            initialCameraPosition: CameraPosition(
              target: LatLng(_startCamera.latitude, _startCamera.longitude),
              zoom: _startCamera.zoom,
            ),
            myLocationEnabled: hasPermission,
            myLocationRenderMode: MyLocationRenderMode.compass,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            compassEnabled: true,
            compassViewPosition: CompassViewPosition.topRight,
            compassViewMargins: const Point(16, 56),
            trackCameraPosition: true,
            attributionButtonPosition: AttributionButtonPosition.bottomRight,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onCameraIdle: _onCameraIdle,
          ),
        ),
        Positioned(
          left: 16,
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
          child: MapScaleIndicator(camera: camera),
        ),
        Positioned(
          right: 16,
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
          child: SafeArea(
            child: MapControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onRecenter: _resetOrientation,
              onMyLocation: _goToMyLocation,
              myLocationActive: hasPermission,
            ),
          ),
        ),
      ],
    );
  }
}
