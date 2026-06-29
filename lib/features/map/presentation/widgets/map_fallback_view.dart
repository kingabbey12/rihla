import 'dart:ui' as ui;

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
import 'package:rihla/features/map/domain/models/map_view_status.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/map/presentation/widgets/map_controls.dart';
import 'package:rihla/features/map/presentation/widgets/map_scale_indicator.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';
import 'package:rihla/features/traffic/presentation/providers/traffic_providers.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Interactive raster-tile map used on platforms without a native MapLibre
/// engine (e.g. macOS desktop). Built on the pure-Dart [FlutterMap] so the user
/// gets a real, pannable/zoomable OpenStreetMap with a live location marker —
/// never a blank white screen.
///
/// The native MapLibre path (Android/iOS) is unchanged; this is only the
/// desktop/unsupported fallback.
///
/// Note on tilt: [FlutterMap] renders a flat 2D projection and cannot pitch the
/// camera, so the Waze-style 45–60° tilt is approximated with heading-up
/// rotation + speed-based dynamic zoom + a forward look-ahead offset. The native
/// MapLibre path supports true tilt.
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
  /// the user manually pans, re-enabled by tapping my-location / double-tap.
  bool _followLocation = true;

  /// Signature of the last route framed, so the camera fits the route exactly
  /// once when it first appears (and not on every rebuild).
  String? _lastFramedRoute;

  /// Drives smooth camera glides (center + zoom + rotation). A single in-flight
  /// animation is kept so a new target seamlessly retargets from the current
  /// position.
  AnimationController? _camAnim;

  /// Last follow target/zoom/rotation we animated toward, so follow-mode only
  /// glides when something actually changed (not on every rebuild).
  LatLng? _lastFollowedTarget;
  double _lastFollowedZoom = _focusZoom;
  double _lastFollowedRotation = 0;

  /// Drives the one-shot "draw-on" reveal of a newly selected route.
  AnimationController? _routeDrawAnim;
  double _routeDrawT = 1;
  String? _drawnRouteSignature;

  /// Sequence counters for provider-driven recenter / overview requests.
  int _lastRecenterSeq = 0;
  int _lastOverviewSeq = 0;

  /// Tracks the arrival edge so the camera zooms out exactly once on arrival.
  bool _arrivedHandled = false;

  @override
  void initState() {
    super.initState();
    // Resolve permission, then start a live location stream so the marker moves
    // and the camera can follow.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _camAnim?.dispose();
    _routeDrawAnim?.dispose();
    super.dispose();
  }

  /// Smoothly animates the map camera to [destCenter]/[destZoom]/[destRotation]
  /// by tweening from the current camera. Replaces any in-flight glide so motion
  /// stays continuous (e.g. while following a moving location).
  void _animateCamera(
    LatLng destCenter,
    double destZoom, {
    double? destRotation,
    Duration duration = const Duration(milliseconds: 650),
    Curve curve = Curves.easeInOutCubic,
  }) {
    _camAnim?.dispose();

    final startCenter = _controller.camera.center;
    final startZoom = _controller.camera.zoom;
    final startRotation = _controller.camera.rotation;
    final endRotation = destRotation ?? startRotation;

    // Take the shortest angular path so heading-up rotation never spins the
    // long way around (e.g. 350° → 10°).
    var rotationDelta = (endRotation - startRotation) % 360;
    if (rotationDelta > 180) rotationDelta -= 360;
    if (rotationDelta < -180) rotationDelta += 360;

    final sameSpot = (startCenter.latitude - destCenter.latitude).abs() < 1e-7 &&
        (startCenter.longitude - destCenter.longitude).abs() < 1e-7 &&
        (startZoom - destZoom).abs() < 1e-3 &&
        rotationDelta.abs() < 0.2;
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
      final t = animation.value;
      _controller.moveAndRotate(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
        startRotation + rotationDelta * t,
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

  /// Dynamic navigation zoom: zoom in when crawling, out on the highway, with a
  /// smooth continuum between so the glide never snaps.
  static double _navZoomForSpeed(double speedKmh) {
    const slow = 17.5; // < 20 km/h
    const fast = 13.5; // > 110 km/h
    final t = (speedKmh.clamp(20, 110) - 20) / 90;
    return slow + (fast - slow) * t;
  }

  /// Look-ahead distance (meters) projected in front of the vehicle so the road
  /// ahead, not behind, dominates the view.
  static double _lookAheadMeters(double speedKmh) =>
      80 + (speedKmh.clamp(0, 120) / 120) * 420;

  static LatLng _toLatLng(RouteCoordinate c) => LatLng(c.latitude, c.longitude);

  /// Traffic colour ramp (green → orange → red → dark red) used for the route
  /// casing so live congestion is visible directly on the line.
  static Color? _trafficColor(TrafficDensity? density) => switch (density) {
        TrafficDensity.freeFlow => const Color(0xFF22C55E),
        TrafficDensity.light => const Color(0xFF22C55E),
        TrafficDensity.moderate => const Color(0xFFF59E0B),
        TrafficDensity.heavy => const Color(0xFFEF4444),
        TrafficDensity.standstill => const Color(0xFF991B1B),
        null => null,
      };

  /// Computes the polylines, destination marker, and framing points for the
  /// current route/navigation state.
  _RouteRender _buildRouteRender({
    required BuildContext context,
    required RouteState routeState,
    required List<RouteCoordinate>? navPolyline,
    required LatLng? origin,
    required JourneyState journeyState,
    required bool isNavigating,
    required TrafficDensity? trafficDensity,
    required double drawT,
  }) {
    final theme = Theme.of(context);
    final teal = RihlaReferenceTokens.mapTeal;
    const routeBlue = Color(0xFF2563EB);
    final altColor = theme.colorScheme.outline.withValues(alpha: 0.45);

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

    final glowLines = <Polyline>[];
    final polylines = <Polyline>[];
    List<RouteCoordinate>? mainCoords;
    String signature = 'none';
    LatLng? destination;
    final framePoints = <LatLng>[];

    if (routes.isNotEmpty && selected != null) {
      // Thin grey alternatives drawn beneath the selected route.
      for (final r in routes.where((r) => r.id != selected.id)) {
        if (r.coordinates.length < 2) continue;
        polylines.add(
          Polyline(
            points: r.coordinates.map(_toLatLng).toList(),
            color: altColor,
            strokeWidth: 3.5,
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
              color: teal.withValues(alpha: 0.85),
              strokeWidth: 5,
              pattern: StrokePattern.dotted(),
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
      final fullPts = mainCoords.map(_toLatLng).toList();
      framePoints.addAll(fullPts);
      if (origin != null) framePoints.add(origin);
      destination = fullPts.last;

      // Progressive "draw-on" reveal for a freshly selected route.
      final revealCount =
          (fullPts.length * drawT).clamp(2, fullPts.length).round();
      final pts = fullPts.sublist(0, revealCount);

      // Soft glow / casing under the route. When navigating with live traffic
      // the casing adopts the congestion colour; otherwise it's a teal glow.
      final casing = isNavigating ? _trafficColor(trafficDensity) : null;
      glowLines.add(
        Polyline(
          points: pts,
          color: (casing ?? teal).withValues(alpha: casing != null ? 0.55 : 0.20),
          strokeWidth: 16,
        ),
      );

      // Thick gradient core line.
      polylines.add(
        Polyline(
          points: pts,
          strokeWidth: 7,
          gradientColors: [
            const Color(0xFF22D3EE),
            teal,
            routeBlue,
          ],
        ),
      );
    }

    return _RouteRender(
      glowLines: glowLines,
      polylines: polylines,
      destination: destination,
      framePoints: framePoints,
      signature: signature,
    );
  }

  Future<void> _goToMyLocation() async {
    _resumeFollow();
    final state = ref.read(locationControllerProvider);
    if (state is! LocationActive) {
      await _initLocation();
      ref.read(mapLocationUnavailableProvider.notifier).show();
    }
  }

  /// Re-enables follow mode and immediately recenters on the user.
  void _resumeFollow() {
    _followLocation = true;
    _lastFollowedTarget = null; // force a fresh glide on next build
    final state = ref.read(locationControllerProvider);
    if (state is LocationActive) {
      _animateCamera(
        LatLng(state.position.latitude, state.position.longitude),
        _controller.camera.zoom < _focusZoom
            ? _focusZoom
            : _controller.camera.zoom,
      );
    }
    if (mounted) setState(() {});
  }

  /// Frames the entire active route (overview) and pauses follow-mode.
  void _showRouteOverview(List<LatLng> framePoints) {
    if (framePoints.length < 2) return;
    _followLocation = false;
    final fit = CameraFit.coordinates(
      coordinates: framePoints,
      padding: const EdgeInsets.fromLTRB(56, 140, 56, 260),
      maxZoom: 16,
    ).fit(_controller.camera);
    _animateCamera(
      fit.center,
      fit.zoom,
      destRotation: 0,
      duration: const Duration(milliseconds: 700),
    );
  }

  void _maybeStartDrawOn(String signature, bool hasRoute) {
    if (!hasRoute) {
      _drawnRouteSignature = null;
      _routeDrawT = 1;
      return;
    }
    if (signature == _drawnRouteSignature) return;
    _drawnRouteSignature = signature;
    _routeDrawAnim?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _routeDrawAnim = controller;
    final curved = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
    controller.addListener(() {
      if (!mounted) return;
      setState(() => _routeDrawT = curved.value);
    });
    controller.forward();
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

    final journeyState = ref.watch(journeyControllerProvider);
    final routeState = ref.watch(routeControllerProvider);
    final navPolyline = ref.watch(mapRoutePolylineProvider);
    final isNavigating = ref.watch(navigationIsActiveProvider);
    final trafficDensity = ref.watch(trafficDensityProvider);

    // Heading / speed: prefer the live navigation session, fall back to the GPS
    // fix so the puck still orients before a session starts.
    final navHeading = ref.watch(navigationHeadingProvider);
    final navSpeed = ref.watch(navigationSpeedProvider);
    final double? heading = navHeading ??
        (locationState is LocationActive ? locationState.position.heading : null);
    final double speedKmh = navSpeed ??
        (locationState is LocationActive
            ? (locationState.position.speed ?? 0) * 3.6
            : 0);

    _maybeStartDrawOn(
      switch (routeState) {
        RouteSelected(:final selected) => 'sel:${selected.id}',
        RouteReady(:final result) => 'ready:${result.primary?.id}',
        _ => 'none',
      },
      routeState is RouteSelected || routeState is RouteReady,
    );

    final routeRender = _buildRouteRender(
      context: context,
      routeState: routeState,
      navPolyline: navPolyline,
      origin: userLatLng,
      journeyState: journeyState,
      isNavigating: isNavigating,
      trafficDensity: trafficDensity,
      drawT: _routeDrawT,
    );

    // Provider-driven recenter / overview requests (from nav controls).
    final recenterSeq = ref.watch(navigationFollowRecenterProvider);
    if (recenterSeq != _lastRecenterSeq) {
      _lastRecenterSeq = recenterSeq;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resumeFollow();
      });
    }
    final overviewSeq = ref.watch(navigationOverviewRequestProvider);
    if (overviewSeq != _lastOverviewSeq) {
      _lastOverviewSeq = overviewSeq;
      final pts = List<LatLng>.from(routeRender.framePoints);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRouteOverview(pts);
      });
    }

    // On arrival, ease the camera out around the destination so the pulsing
    // pin and the surroundings come into view (Waze-style zoom-out).
    final hasArrived = ref.watch(navigationHasArrivedProvider);
    if (hasArrived && !_arrivedHandled) {
      _arrivedHandled = true;
      _followLocation = false;
      final dest = routeRender.destination ?? userLatLng;
      if (dest != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _animateCamera(
            dest,
            13.5,
            destRotation: 0,
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
          );
        });
      }
    } else if (!hasArrived && _arrivedHandled) {
      _arrivedHandled = false;
    }

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
        final fit = CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.fromLTRB(48, 120, 48, 280),
          maxZoom: 16,
        ).fit(_controller.camera);
        _animateCamera(
          fit.center,
          fit.zoom,
          destRotation: 0,
          duration: const Duration(milliseconds: 850),
        );
      });
    } else if (routeRender.framePoints.isEmpty && _lastFramedRoute != null) {
      _lastFramedRoute = null;
      _followLocation = true;
    }

    // Follow the live (moving) location. While navigating, rotate heading-up,
    // zoom dynamically with speed, and look ahead of the vehicle.
    if (userLatLng != null && _followLocation) {
      final double targetRotation =
          isNavigating && heading != null ? -heading : 0;
      final double targetZoom = isNavigating
          ? _navZoomForSpeed(speedKmh)
          : (_centeredOnUser ? _controller.camera.zoom : _focusZoom);

      LatLng targetCenter = userLatLng;
      if (isNavigating && heading != null) {
        // Project the camera centre ahead so the puck sits in the lower third.
        targetCenter = const Distance()
            .offset(userLatLng, _lookAheadMeters(speedKmh), heading);
      }

      final moved = _lastFollowedTarget == null ||
          (_lastFollowedTarget!.latitude - targetCenter.latitude).abs() > 1e-7 ||
          (_lastFollowedTarget!.longitude - targetCenter.longitude).abs() > 1e-7;
      final rotated = (_lastFollowedRotation - targetRotation).abs() > 1.0;
      final zoomed = (_lastFollowedZoom - targetZoom).abs() > 0.05;

      if (moved || rotated || zoomed) {
        _lastFollowedTarget = targetCenter;
        _lastFollowedRotation = targetRotation;
        _lastFollowedZoom = targetZoom;
        final firstFix = !_centeredOnUser;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _centeredOnUser = true;
          if (firstFix) {
            _controller.moveAndRotate(targetCenter, targetZoom, targetRotation);
            ref.read(mapUserLocationResolvedProvider.notifier).resolve();
            ref.read(mapViewStatusProvider.notifier).set(const MapReady());
          } else {
            _animateCamera(
              targetCenter,
              targetZoom,
              destRotation: targetRotation,
              duration: Duration(milliseconds: isNavigating ? 700 : 900),
              curve: isNavigating ? Curves.easeOut : Curves.linear,
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
              interactionOptions: InteractionOptions(
                // Rotation is driven programmatically (heading-up). While
                // navigating we also free up double-tap for "resume follow".
                flags: isNavigating
                    ? InteractiveFlag.all &
                        ~InteractiveFlag.rotate &
                        ~InteractiveFlag.doubleTapZoom
                    : InteractiveFlag.all & ~InteractiveFlag.rotate,
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
              if (routeRender.glowLines.isNotEmpty)
                PolylineLayer(polylines: routeRender.glowLines),
              if (routeRender.polylines.isNotEmpty)
                PolylineLayer(polylines: routeRender.polylines),
              if (routeRender.destination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: routeRender.destination!,
                      width: 48,
                      height: 56,
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
                      width: 40,
                      height: 40,
                      child: _LocationPuck(
                        heading: heading,
                        navigating: isNavigating,
                      ),
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
    required this.glowLines,
    required this.polylines,
    required this.destination,
    required this.framePoints,
    required this.signature,
  });

  final List<Polyline> glowLines;
  final List<Polyline> polylines;
  final LatLng? destination;
  final List<LatLng> framePoints;
  final String signature;
}

/// Premium destination pin with a soft pulsing halo.
class _DestinationPin extends StatefulWidget {
  const _DestinationPin();

  @override
  State<_DestinationPin> createState() => _DestinationPinState();
}

class _DestinationPinState extends State<_DestinationPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teal = RihlaReferenceTokens.mapTeal;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Expanding halo at the pin tip.
            Positioned(
              bottom: 0,
              child: Container(
                width: 14 + 26 * t,
                height: 14 + 26 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: teal.withValues(alpha: 0.22 * (1 - t)),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [teal, teal.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flag_rounded,
                      color: Colors.white, size: 18),
                ),
                // Pointer triangle.
                Transform.translate(
                  offset: const Offset(0, -3),
                  child: CustomPaint(
                    size: const Size(10, 8),
                    painter: _PinTipPainter(teal),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PinTipPainter extends CustomPainter {
  _PinTipPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Current-location marker: a directional chevron puck that points along the
/// heading while navigating, or a simple dot when idle.
class _LocationPuck extends StatelessWidget {
  const _LocationPuck({required this.heading, required this.navigating});

  final double? heading;
  final bool navigating;

  @override
  Widget build(BuildContext context) {
    final color = RihlaReferenceTokens.mapTeal;

    if (!navigating) {
      // Idle: blue dot, with a subtle heading cone if we know the heading.
      return Center(
        child: Container(
          width: 18,
          height: 18,
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
        ),
      );
    }

    // Navigating: the map is rotated heading-up, so travel direction is screen
    // "up"; the chevron points up.
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.navigation_rounded,
            color: Colors.white, size: 20),
      ),
    );
  }
}
