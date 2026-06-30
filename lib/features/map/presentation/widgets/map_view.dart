import 'dart:async';
import 'dart:math' show Point, max, min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/domain/models/location_result.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/map/data/styles/map_style_catalog.dart';
import 'package:rihla/features/map/domain/entities/map_camera.dart';
import 'package:rihla/features/map/domain/errors/map_failure.dart';
import 'package:rihla/features/map/domain/models/map_view_status.dart';
import 'package:rihla/features/map/presentation/map_platform_support.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/map/presentation/widgets/map_fallback_view.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/traffic/presentation/providers/traffic_providers.dart';
import 'package:rihla/features/traffic/presentation/utils/route_traffic_segments.dart';
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
  Timer? _routeDrawTimer;
  late final MapCamera _startCamera;
  Line? _routeLine;
  Line? _animatedRouteLine;
  final List<Line> _routeAlternativeLines = [];
  final List<Line> _trafficCasingLines = [];
  List<RouteCoordinate>? _pendingPolyline;
  final Map<Circle, ExploreMarker> _exploreCircleMarkers = {};
  Brightness? _lastSyncedBrightness;
  String? _lastMarkerSignature;
  String? _lastRouteSignature;
  bool _centeredOnFirstFix = false;

  /// While navigating, keep the camera locked behind the vehicle (heading-up,
  /// tilted) until the user requests an overview.
  bool _navFollow = true;

  @override
  void initState() {
    super.initState();
    _startCamera = ref.read(mapCameraProvider);
    if (MapPlatformSupport.supportsNativeMap) {
      // Native engine drives the ready/error transitions via its callbacks.
      _startInitTimeout();
    }
    // Start GPS immediately — map centers on the first real fix (never a fixed city).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final notifier = ref.read(locationControllerProvider.notifier);
      await notifier.refreshStatus();
      await notifier.startForegroundStream();
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
    _routeDrawTimer?.cancel();
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
    _renderRouteState(ref.read(routeControllerProvider));
    final routeState = ref.read(routeControllerProvider);
    if (routeState is! RouteReady &&
        routeState is! RouteSelected &&
        _pendingPolyline != null) {
      _renderRouteLine(_pendingPolyline);
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

  Future<void> _clearRouteAlternatives() async {
    _routeDrawTimer?.cancel();
    _routeDrawTimer = null;
    final controller = _controller;
    if (controller == null) return;

    if (_animatedRouteLine != null) {
      await controller.removeLine(_animatedRouteLine!);
      _animatedRouteLine = null;
    }
    for (final line in _routeAlternativeLines) {
      await controller.removeLine(line);
    }
    _routeAlternativeLines.clear();
    await _clearTrafficCasing();
    _lastRouteSignature = null;
  }

  Future<void> _clearTrafficCasing() async {
    final controller = _controller;
    if (controller == null) return;
    for (final line in _trafficCasingLines) {
      await controller.removeLine(line);
    }
    _trafficCasingLines.clear();
  }

  Future<void> _renderTrafficCasing(RouteSummary route) async {
    final controller = _controller;
    if (controller == null || route.coordinates.length < 2) return;

    await _clearTrafficCasing();
    final snapshot = ref.read(trafficSnapshotProvider);
    final segments = buildRouteTrafficSegments(
      route: route.coordinates,
      snapshot: snapshot,
    );

    for (final segment in segments) {
      if (segment.coordinates.length < 2) continue;
      final line = await controller.addLine(
        LineOptions(
          geometry: segment.coordinates
              .map((c) => LatLng(c.latitude, c.longitude))
              .toList(),
          lineColor: trafficColorHex(segment.density),
          lineWidth: 12,
          lineOpacity: 0.58,
        ),
      );
      _trafficCasingLines.add(line);
    }
  }

  Future<void> _renderRouteState(RouteState state) async {
    final controller = _controller;
    if (controller == null) return;

    final routes = switch (state) {
      RouteReady(:final result) => result.routes,
      RouteSelected(:final result) => result.routes,
      _ => const <RouteSummary>[],
    };
    final selected = switch (state) {
      RouteSelected(:final selected) => selected,
      RouteReady(:final result) => result.primary,
      _ => null,
    };

    if (routes.isEmpty || selected == null) {
      await _clearRouteAlternatives();
      return;
    }

    final signature =
        '${routes.map((r) => '${r.id}:${r.coordinates.length}').join('|')}:selected=${selected.id}';
    if (signature == _lastRouteSignature) return;
    _lastRouteSignature = signature;

    _routeDrawTimer?.cancel();
    if (_routeLine != null) {
      await controller.removeLine(_routeLine!);
      _routeLine = null;
    }
    if (_animatedRouteLine != null) {
      await controller.removeLine(_animatedRouteLine!);
      _animatedRouteLine = null;
    }
    for (final line in _routeAlternativeLines) {
      await controller.removeLine(line);
    }
    _routeAlternativeLines.clear();

    // Draw alternatives first so the selected route sits visually on top.
    for (final route in routes.where((r) => r.id != selected.id)) {
      if (route.coordinates.length < 2) continue;
      final line = await controller.addLine(
        LineOptions(
          geometry: route.coordinates
              .map((c) => LatLng(c.latitude, c.longitude))
              .toList(),
          lineColor: _colorForProfile(route.profile, selected: false),
          lineWidth: 4,
          lineOpacity: 0.55,
        ),
      );
      _routeAlternativeLines.add(line);
    }

    await _frameRoutes(routes);
    await _drawSelectedRouteProgressively(selected);
    await _renderTrafficCasing(selected);
  }

  Future<void> _frameRoutes(List<RouteSummary> routes) async {
    final all = routes.expand((route) => route.coordinates).toList();
    if (all.length < 2) return;

    var minLat = all.first.latitude;
    var maxLat = all.first.latitude;
    var minLng = all.first.longitude;
    var maxLng = all.first.longitude;

    for (final coord in all.skip(1)) {
      minLat = min(minLat, coord.latitude);
      maxLat = max(maxLat, coord.latitude);
      minLng = min(minLng, coord.longitude);
      maxLng = max(maxLng, coord.longitude);
    }

    await _animate(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        left: 48,
        top: 112,
        right: 48,
        bottom: 360,
      ),
    );
  }

  Future<void> _drawSelectedRouteProgressively(RouteSummary route) async {
    final controller = _controller;
    final coords = route.coordinates;
    if (controller == null || coords.length < 2) return;

    var count = 2;
    final chunk = (coords.length / 20).ceil().clamp(1, 8);

    Future<void> drawPrefix(int visibleCount) async {
      final visible = coords.take(visibleCount).toList();
      if (visible.length < 2) return;
      if (_animatedRouteLine != null) {
        await controller.removeLine(_animatedRouteLine!);
      }
      _animatedRouteLine = await controller.addLine(
        LineOptions(
          geometry: visible
              .map((c) => LatLng(c.latitude, c.longitude))
              .toList(),
          lineColor: _colorForProfile(route.profile, selected: true),
          lineWidth: 7,
          lineOpacity: 0.95,
        ),
      );
    }

    await drawPrefix(count);
    _routeDrawTimer = Timer.periodic(const Duration(milliseconds: 28), (timer) {
      count = (count + chunk).clamp(2, coords.length);
      drawPrefix(count);
      if (count >= coords.length) {
        timer.cancel();
        _routeDrawTimer = null;
      }
    });
  }

  String _colorForProfile(RouteProfile profile, {required bool selected}) {
    if (!selected) return '#6B7280';
    return switch (profile) {
      RouteProfile.safe => '#0D7C7C',
      RouteProfile.fast => '#2563EB',
      RouteProfile.eco => '#159947',
      RouteProfile.scenic => '#B45309',
    };
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

  /// Dynamic navigation zoom: zoom in when crawling, out on the highway.
  static double _navZoomForSpeed(double speedKmh) {
    const slow = 17.5;
    const fast = 14.0;
    final t = (speedKmh.clamp(20, 110) - 20) / 90;
    return slow + (fast - slow) * t;
  }

  /// Camera follow during navigation: centre on the vehicle, rotate heading-up,
  /// tilt for a 3D forward perspective, and zoom with speed.
  Future<void> _followNavigation(
    LocationPosition position,
    double speedKmh,
    double heading,
  ) async {
    await _animate(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: _navZoomForSpeed(speedKmh),
          bearing: heading,
          tilt: 55,
        ),
      ),
    );
  }

  Future<void> _centerOnGpsFix(LocationPosition position) async {
    await _animate(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        _focusZoom,
      ),
    );
    ref.read(mapCameraProvider.notifier).update(
          MapCamera(
            latitude: position.latitude,
            longitude: position.longitude,
            zoom: _focusZoom,
            bearing: position.heading ?? 0,
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

    ref.listen(locationControllerProvider, (prev, next) {
      if (next is LocationActive && !_centeredOnFirstFix) {
        _centeredOnFirstFix = true;
        _centerOnGpsFix(next.position);
        ref.read(mapUserLocationResolvedProvider.notifier).resolve();
      } else if (next is LocationError) {
        ref.read(mapLocationUnavailableProvider.notifier).show();
      }
    });

    // Platforms without a native MapLibre engine (e.g. macOS desktop) get a
    // real interactive raster-tile map fallback instead of a blank white
    // surface. It is self-contained (tiles, location marker, controls).
    if (!MapPlatformSupport.supportsNativeMap) {
      return const MapFallbackView();
    }

    final recreateKey = ref.watch(mapRecreateProvider);
    ref.listen(mapRecreateProvider, (_, _) => _startInitTimeout());
    ref.listen(mapLocationRetryProvider, (_, _) => _goToMyLocation());
    ref.listen(mapFlyToTargetProvider, (_, next) {
      if (next != null) _flyToTarget(next);
    });
    ref.listen(mapRoutePolylineProvider, (_, next) {
      final routeState = ref.read(routeControllerProvider);
      if (routeState is RouteReady || routeState is RouteSelected) return;
      _renderRouteLine(next);
    });
    ref.listen(routeControllerProvider, (_, next) {
      _renderRouteState(next);
    });
    ref.listen(trafficSnapshotProvider, (_, _) {
      final routeState = ref.read(routeControllerProvider);
      final selected = switch (routeState) {
        RouteSelected(:final selected) => selected,
        RouteReady(:final result) => result.primary,
        _ => null,
      };
      if (selected != null) _renderTrafficCasing(selected);
    });
    ref.listen(exploreMapMarkersProvider, (_, next) {
      _renderExploreMarkers(next);
    });
    ref.listen(navigationIsActiveProvider, (_, next) {
      if (!next) return;
      _navFollow = true;
      final pos = ref.read(navigationCurrentPositionProvider);
      if (pos != null) {
        final speed =
            ref.read(navigationSpeedProvider) ?? (pos.speed ?? 0) * 3.6;
        final heading = ref.read(navigationHeadingProvider) ?? pos.heading ?? 0;
        _followNavigation(pos, speed, heading);
      }
    });
    ref.listen(navigationCurrentPositionProvider, (_, next) {
      if (next == null || !_navFollow) return;
      if (!ref.read(navigationIsActiveProvider)) return;
      final speed =
          ref.read(navigationSpeedProvider) ?? (next.speed ?? 0) * 3.6;
      final heading = ref.read(navigationHeadingProvider) ?? next.heading ?? 0;
      _followNavigation(next, speed, heading);
    });
    ref.listen(navigationFollowRecenterProvider, (_, _) {
      _navFollow = true;
      final pos = ref.read(navigationCurrentPositionProvider);
      if (pos == null) return;
      final speed = ref.read(navigationSpeedProvider) ?? (pos.speed ?? 0) * 3.6;
      final heading = ref.read(navigationHeadingProvider) ?? pos.heading ?? 0;
      _followNavigation(pos, speed, heading);
    });
    ref.listen(navigationOverviewRequestProvider, (_, _) {
      _navFollow = false;
      final route = ref.read(navigationSessionProvider)?.route;
      if (route != null) _frameRoutes([route]);
    });
    ref.listen(navigationHasArrivedProvider, (_, arrived) {
      if (!arrived) return;
      // Ease out of the tilted follow view so arrival feels like a settle.
      _navFollow = false;
      final pos = ref.read(navigationCurrentPositionProvider);
      _animate(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: pos != null
                ? LatLng(pos.latitude, pos.longitude)
                : LatLng(_startCamera.latitude, _startCamera.longitude),
            zoom: 14,
            tilt: 0,
            bearing: 0,
          ),
        ),
      );
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
            // MapLibre asserts that a non-normal render mode requires
            // myLocationEnabled; fall back to normal until permission is granted.
            myLocationRenderMode: hasPermission
                ? MyLocationRenderMode.compass
                : MyLocationRenderMode.normal,
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
