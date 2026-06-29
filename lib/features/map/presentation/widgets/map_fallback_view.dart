import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide MapCamera;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/map/domain/entities/map_camera.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/map/presentation/widgets/map_controls.dart';
import 'package:rihla/features/map/presentation/widgets/map_scale_indicator.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';

/// Interactive raster-tile map used on platforms without a native MapLibre
/// engine (e.g. macOS desktop). Built on the pure-Dart [FlutterMap] so the user
/// gets a real, pannable/zoomable OpenStreetMap with a live location marker —
/// never a blank white screen.
///
/// The native MapLibre path (Android/iOS) is unchanged; this is only the
/// desktop/unsupported fallback.
class MapFallbackView extends ConsumerStatefulWidget {
  const MapFallbackView({super.key});

  @override
  ConsumerState<MapFallbackView> createState() => _MapFallbackViewState();
}

class _MapFallbackViewState extends ConsumerState<MapFallbackView>
    with TickerProviderStateMixin {
  static const double _focusZoom = 15.5;
  static const double _minZoom = 3;
  static const double _maxZoom = 19;

  final MapController _controller = MapController();
  bool _centeredOnUser = false;

  /// When true, the camera keeps following the moving location. Disabled once
  /// the user manually pans, re-enabled by tapping my-location.
  bool _followLocation = true;

  /// Signature of the last route framed, so the camera fits the route exactly
  /// once when it first appears (and not on every rebuild).
  String? _lastFramedRoute;

  /// Drives smooth camera glides (center + zoom). A single in-flight animation
  /// is kept so a new target seamlessly retargets from the current position.
  AnimationController? _camAnim;

  /// Last location we animated the camera toward, so follow-mode only glides
  /// when the position actually changes (not on every rebuild).
  LatLng? _lastFollowedTarget;

  @override
  void initState() {
    super.initState();
    // Resolve permission, then start a live (simulated on desktop) location
    // stream so the marker moves and the camera can follow.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _camAnim?.dispose();
    super.dispose();
  }

  /// Smoothly animates the map camera to [destCenter]/[destZoom] by tweening
  /// from the current camera. Replaces any in-flight glide so motion stays
  /// continuous (e.g. while following a moving location).
  void _animateCamera(
    LatLng destCenter,
    double destZoom, {
    Duration duration = const Duration(milliseconds: 650),
    Curve curve = Curves.easeInOutCubic,
  }) {
    _camAnim?.dispose();

    final startCenter = _controller.camera.center;
    final startZoom = _controller.camera.zoom;

    // Skip imperceptible moves to avoid needless work.
    final sameSpot = (startCenter.latitude - destCenter.latitude).abs() < 1e-7 &&
        (startCenter.longitude - destCenter.longitude).abs() < 1e-7 &&
        (startZoom - destZoom).abs() < 1e-3;
    if (sameSpot) {
      _camAnim = null;
      return;
    }

    final latTween =
        Tween<double>(begin: startCenter.latitude, end: destCenter.latitude);
    final lngTween =
        Tween<double>(begin: startCenter.longitude, end: destCenter.longitude);
    final zoomTween = Tween<double>(begin: startZoom, end: destZoom);

    final controller = AnimationController(vsync: this, duration: duration);
    _camAnim = controller;
    final animation = CurvedAnimation(parent: controller, curve: curve);

    controller.addListener(() {
      _controller.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
        if (identical(_camAnim, controller)) _camAnim = null;
      }
    });
    controller.forward();
  }

  Future<void> _initLocation() async {
    try {
      final notifier = ref.read(locationControllerProvider.notifier);
      final repository = ref.read(locationRepositoryProvider);
      var permission = await repository.getPermissionStatus();
      if (permission != LocationPermissionStatus.granted) {
        await notifier.requestPermission();
        permission = await repository.getPermissionStatus();
      }
      if (permission == LocationPermissionStatus.granted) {
        await notifier.startForegroundStream();
      }
    } catch (_) {
      // Location is best-effort here; the map still renders without a fix.
    }
  }

  void _syncCamera() {
    final center = _controller.camera.center;
    final zoom = _controller.camera.zoom;
    ref.read(mapCameraProvider.notifier).update(
          MapCamera(
            latitude: center.latitude,
            longitude: center.longitude,
            zoom: zoom,
          ),
        );
  }

  void _zoomIn() => _animateCamera(
        _controller.camera.center,
        (_controller.camera.zoom + 1).clamp(_minZoom, _maxZoom),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );

  void _zoomOut() => _animateCamera(
        _controller.camera.center,
        (_controller.camera.zoom - 1).clamp(_minZoom, _maxZoom),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );

  void _resetOrientation() => _controller.rotate(0);

  static LatLng _toLatLng(RouteCoordinate c) => LatLng(c.latitude, c.longitude);

  /// Computes the polylines, destination marker, and framing points for the
  /// current route/navigation state.
  _RouteRender _buildRouteRender({
    required BuildContext context,
    required RouteState routeState,
    required List<RouteCoordinate>? navPolyline,
    required LatLng? origin,
    required JourneyState journeyState,
  }) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final altColor = theme.colorScheme.outline.withValues(alpha: 0.7);

    final routes = switch (routeState) {
      RouteReady(:final result) => result.routes,
      RouteSelected(:final result) => result.routes,
      _ => const <RouteSummary>[],
    };
    final selected = switch (routeState) {
      RouteSelected(:final selected) => selected,
      RouteReady(:final result) => result.primary,
      _ => null,
    };

    final polylines = <Polyline>[];
    List<RouteCoordinate>? mainCoords;
    String signature = 'none';
    LatLng? destination;
    final framePoints = <LatLng>[];

    if (routes.isNotEmpty && selected != null) {
      for (final r in routes.where((r) => r.id != selected.id)) {
        if (r.coordinates.length < 2) continue;
        polylines.add(
          Polyline(
            points: r.coordinates.map(_toLatLng).toList(),
            color: altColor,
            strokeWidth: 4,
          ),
        );
      }
      if (selected.coordinates.length >= 2) mainCoords = selected.coordinates;
      signature = 'sel:${selected.id}:${selected.coordinates.length}'
          ':alts=${routes.length}';
    } else if (navPolyline != null && navPolyline.length >= 2) {
      mainCoords = navPolyline;
      signature = 'nav:${navPolyline.length}:'
          '${navPolyline.last.latitude.toStringAsFixed(4)}';
    } else {
      // Journey preview: draw a direction line from you → destination before
      // the routing engine returns turn-by-turn polylines.
      final JourneySummary? previewSummary = switch (journeyState) {
        JourneyPreview(:final summary) => summary,
        JourneyStarted(:final summary) => summary,
        _ => null,
      };
      if (previewSummary != null) {
        final dest = previewSummary.destination;
        final start = origin ??
            LatLng(previewSummary.origin.latitude, previewSummary.origin.longitude);
        final end = LatLng(dest.latitude, dest.longitude);
        if (start.latitude != end.latitude || start.longitude != end.longitude) {
          polylines.add(
            Polyline(
              points: [start, end],
              color: selectedColor.withValues(alpha: 0.9),
              strokeWidth: 5,
            ),
          );
          destination = end;
          framePoints.addAll([start, end]);
          signature =
              'preview:${dest.id ?? dest.name}:${dest.latitude.toStringAsFixed(4)}';
        }
      }
    }

    if (mainCoords != null) {
      final pts = mainCoords.map(_toLatLng).toList();
      polylines.add(
        Polyline(points: pts, color: selectedColor, strokeWidth: 6),
      );
      destination = pts.last;
      framePoints.addAll(pts);
      if (origin != null) framePoints.add(origin);
    }

    return _RouteRender(
      polylines: polylines,
      destination: destination,
      framePoints: framePoints,
      signature: signature,
    );
  }

  Future<void> _goToMyLocation() async {
    _followLocation = true;
    final state = ref.read(locationControllerProvider);
    if (state is LocationActive) {
      final target = LatLng(state.position.latitude, state.position.longitude);
      _lastFollowedTarget = target;
      _animateCamera(target, _focusZoom);
    } else {
      await _initLocation();
      ref.read(mapLocationUnavailableProvider.notifier).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final camera = ref.watch(mapCameraProvider);
    final locationState = ref.watch(locationControllerProvider);

    final hasPermission = switch (locationState) {
      LocationIdle(:final permissionStatus) =>
        permissionStatus == LocationPermissionStatus.granted,
      LocationLoading(:final permissionStatus) =>
        permissionStatus == LocationPermissionStatus.granted,
      LocationActive(:final permissionStatus) =>
        permissionStatus == LocationPermissionStatus.granted,
      LocationError(:final permissionStatus) =>
        permissionStatus == LocationPermissionStatus.granted,
    };

    LatLng? userLatLng;
    if (locationState is LocationActive) {
      userLatLng = LatLng(
        locationState.position.latitude,
        locationState.position.longitude,
      );
    }

    // Build the direction line(s): alternatives during route selection, and the
    // selected/active route during selection + navigation.
    final journeyState = ref.watch(journeyControllerProvider);
    final routeState = ref.watch(routeControllerProvider);
    final navPolyline = ref.watch(mapRoutePolylineProvider);
    final isNavigating = ref.watch(navigationIsActiveProvider);
    final routeRender = _buildRouteRender(
      context: context,
      routeState: routeState,
      navPolyline: navPolyline,
      origin: userLatLng,
      journeyState: journeyState,
    );

    // Frame the whole route once when it first appears (preview/selection).
    // While navigating we keep following the live location instead.
    if (routeRender.framePoints.length >= 2 &&
        routeRender.signature != _lastFramedRoute &&
        !isNavigating) {
      _lastFramedRoute = routeRender.signature;
      _followLocation = false;
      final points = routeRender.framePoints;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Resolve the fit to a target center+zoom, then glide there smoothly.
        final fit = CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.fromLTRB(48, 120, 48, 280),
          maxZoom: 16,
        ).fit(_controller.camera);
        _animateCamera(
          fit.center,
          fit.zoom,
          duration: const Duration(milliseconds: 850),
        );
      });
    } else if (routeRender.framePoints.isEmpty && _lastFramedRoute != null) {
      // Route cleared — resume following the user.
      _lastFramedRoute = null;
      _followLocation = true;
    }

    // Follow the live (moving) location: center on the first fix, then keep the
    // camera gliding with the vehicle as it drives, until the user manually
    // pans away. Only animate when the position actually changed so the glide
    // isn't restarted on every rebuild.
    if (userLatLng != null && _followLocation) {
      final target = userLatLng;
      final moved = _lastFollowedTarget == null ||
          (_lastFollowedTarget!.latitude - target.latitude).abs() > 1e-7 ||
          (_lastFollowedTarget!.longitude - target.longitude).abs() > 1e-7;
      if (moved) {
        _lastFollowedTarget = target;
        final firstFix = !_centeredOnUser;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final zoom = firstFix ? _focusZoom : _controller.camera.zoom;
          _centeredOnUser = true;
          if (firstFix) {
            // Snap the very first fix into view, then glide afterwards.
            _controller.move(target, zoom);
          } else {
            _animateCamera(
              target,
              zoom,
              duration: const Duration(milliseconds: 900),
              curve: Curves.linear,
            );
          }
        });
      }
    }

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: LatLng(camera.latitude, camera.longitude),
              initialZoom: camera.zoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) _followLocation = false;
                _syncCamera();
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rihla.app',
                tileBuilder: isDark
                    ? (context, tileWidget, tile) => ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            -0.6, 0, 0, 0, 255, //
                            0, -0.6, 0, 0, 255, //
                            0, 0, -0.6, 0, 255, //
                            0, 0, 0, 1, 0, //
                          ]),
                          child: tileWidget,
                        )
                    : null,
              ),
              if (routeRender.polylines.isNotEmpty)
                PolylineLayer(polylines: routeRender.polylines),
              if (routeRender.destination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: routeRender.destination!,
                      width: 36,
                      height: 36,
                      alignment: Alignment.topCenter,
                      child: const _DestinationPin(),
                    ),
                  ],
                ),
              if (userLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLatLng,
                      width: 28,
                      height: 28,
                      child: const _LocationPuck(),
                    ),
                  ],
                ),
            ],
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

/// Immutable bundle describing what to draw for the current route state.
class _RouteRender {
  const _RouteRender({
    required this.polylines,
    required this.destination,
    required this.framePoints,
    required this.signature,
  });

  final List<Polyline> polylines;
  final LatLng? destination;
  final List<LatLng> framePoints;
  final String signature;
}

/// Destination pin marker drawn at the end of the route.
class _DestinationPin extends StatelessWidget {
  const _DestinationPin();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.place,
      size: 36,
      color: Theme.of(context).colorScheme.primary,
      shadows: const [
        Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
      ],
    );
  }
}

/// The blue-dot style current-location marker.
class _LocationPuck extends StatelessWidget {
  const _LocationPuck();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
