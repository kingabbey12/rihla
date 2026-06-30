import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/observability/breadcrumb.dart';
import 'package:rihla/core/observability/observability_providers.dart';
import 'package:rihla/core/providers/network_providers.dart';
import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/routing/data/datasources/valhalla_route_datasource.dart';
import 'package:rihla/features/offline/data/repositories/offline_aware_route_repository.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';
import 'package:rihla/features/routing/data/repositories/route_repository_impl.dart';
import 'package:rihla/features/routing/data/services/mock_route_service.dart';
import 'package:rihla/features/routing/data/services/valhalla_route_service.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_point.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/errors/route_failure.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/domain/repositories/route_repository.dart';
import 'package:rihla/features/routing/domain/services/route_service.dart';
import 'package:rihla/features/traffic/presentation/providers/traffic_providers.dart';

/// Provides the Valhalla-backed [RouteService] (production HTTP).
final valhallaRouteServiceProvider = Provider<RouteService>((ref) {
  final datasource = ValhallaRouteDatasource(ref.watch(apiClientProvider));
  return ValhallaRouteService(datasource, logger: ref.watch(appLoggerProvider));
});

/// Production Valhalla routing on all platforms.
final routeServiceProvider = Provider<RouteService>(
  (ref) => ref.watch(valhallaRouteServiceProvider),
);

/// Mock route service for development and tests.
final mockRouteServiceProvider = Provider<RouteService>(
  (ref) => MockRouteService(simulatedDelay: Duration.zero),
);

final routeRepositoryProvider = Provider<RouteRepository>(
  (ref) => OfflineAwareRouteRepository(
    isOffline: () => ref.read(isOfflineModeProvider),
    online: RouteRepositoryImpl(ref.watch(routeServiceProvider)),
    offline: ref.watch(offlineRouteRepositoryProvider),
  ),
);

/// Direct online route repository (tests / overrides).
final onlineRouteRepositoryDirectProvider = Provider<RouteRepository>(
  (ref) => RouteRepositoryImpl(ref.watch(routeServiceProvider)),
);

/// Polyline coordinates to render on the map (null = clear).
final mapRoutePolylineProvider =
    NotifierProvider<MapRoutePolylineNotifier, List<RouteCoordinate>?>(
  MapRoutePolylineNotifier.new,
);

class MapRoutePolylineNotifier extends Notifier<List<RouteCoordinate>?> {
  @override
  List<RouteCoordinate>? build() => null;

  void set(List<RouteCoordinate>? coordinates) => state = coordinates;
  void clear() => state = null;
}

/// Central routing state machine.
final routeControllerProvider =
    NotifierProvider<RouteController, RouteState>(RouteController.new);

class RouteController extends Notifier<RouteState> {
  RouteRequest? _lastRequest;

  @override
  RouteState build() => const RouteIdle();

  Future<void> fetchRoutes(RouteRequest request) async {
    _lastRequest = request;
    state = const RouteLoading();
    final logger = ref.read(appLoggerProvider);
    logger.log(
      'route_fetch_request',
      category: ObservabilityCategory.navigation,
      data: {
        'origin': '${request.origin.latitude.toStringAsFixed(6)},'
            '${request.origin.longitude.toStringAsFixed(6)}',
        'destination': '${request.destination.latitude.toStringAsFixed(6)},'
            '${request.destination.longitude.toStringAsFixed(6)}',
        'provider': ref.read(isOfflineModeProvider) ? 'offline' : 'valhalla',
      },
    );
    try {
      final result = await ref.read(routeRepositoryProvider).getRoutes(request);
      logger.log(
        'route_received',
        category: ObservabilityCategory.navigation,
        data: {
          'routes': result.routes.length.toString(),
          if (result.primary != null)
            'primary_distance_km':
                result.primary!.distanceKm.toStringAsFixed(2),
          if (result.primary != null)
            'primary_duration_s': result.primary!.durationSeconds.toString(),
        },
      );
      state = RouteReady(result);

      // Auto-select the primary route so the polyline draws immediately and the
      // Start Navigation (Confirm) button is enabled — no extra tap required.
      final primaryId = result.primaryRouteId ?? result.routes.firstOrNull?.id;
      if (primaryId != null) {
        selectRoute(primaryId);
        logger.log(
          'route_primary_selected',
          category: ObservabilityCategory.navigation,
          data: {'route_id': primaryId},
        );
      }
    } on RouteFailure catch (failure) {
      logger.log(
        'route_fetch_failed',
        category: ObservabilityCategory.navigation,
        data: {
          'type': failure.runtimeType.toString(),
          'message': failure.message,
        },
      );
      state = RouteError(failure);
    } catch (e) {
      logger.log(
        'route_fetch_exception',
        category: ObservabilityCategory.navigation,
        data: {'error': e.toString()},
      );
      state = RouteError(RouteUnknownFailure(e.toString()));
    }
  }

  Future<void> fetchFromJourney(JourneySummary summary) async {
    await fetchRoutes(
      RouteRequest(
        origin: _pointFromEndpoint(summary.origin),
        destination: _pointFromEndpoint(summary.destination),
      ),
    );
  }

  void selectRoute(String routeId) {
    final current = state;
    final RouteResult result;
    if (current is RouteReady) {
      result = current.result;
    } else if (current is RouteSelected) {
      result = current.result;
    } else {
      return;
    }
    RouteSummary? selected;
    for (final r in result.routes) {
      if (r.id == routeId) {
        selected = r;
        break;
      }
    }
    if (selected == null) return;
    state = RouteSelected(result: result, selected: selected);
    ref.read(mapRoutePolylineProvider.notifier).set(selected.coordinates);
    unawaited(_refreshTrafficForRoute(selected));
  }

  Future<void> _refreshTrafficForRoute(RouteSummary route) async {
    if (route.coordinates.length < 2) return;
    await ref.read(trafficControllerProvider.notifier).fetchAlongRoute(
          coordinates: [
            for (final c in route.coordinates)
              (latitude: c.latitude, longitude: c.longitude),
          ],
          freeFlowDurationMinutes: route.durationSeconds / 60,
        );
  }

  void confirmSelection() {
    final current = state;
    if (current is! RouteSelected) return;
    state = RouteConfirmed(current.selected);
  }

  void acknowledgeConfirmed() {
    _lastRequest = null;
    state = const RouteIdle();
  }

  Future<void> retry() async {
    final request = _lastRequest;
    if (request != null) await fetchRoutes(request);
  }

  void clear() {
    _lastRequest = null;
    ref.read(mapRoutePolylineProvider.notifier).clear();
    state = const RouteIdle();
  }

  RoutePoint _pointFromEndpoint(JourneyEndpoint endpoint) => RoutePoint(
        id: endpoint.id,
        name: endpoint.name,
        latitude: endpoint.latitude,
        longitude: endpoint.longitude,
      );
}

/// True while the route preview / selection sheet should own the bottom of the
/// screen (hide the home tab bar so Start Navigation is never covered).
final routePreviewActiveProvider = Provider<bool>((ref) {
  return switch (ref.watch(routeControllerProvider)) {
    RouteLoading() || RouteReady() || RouteSelected() || RouteError() => true,
    _ => false,
  };
});
