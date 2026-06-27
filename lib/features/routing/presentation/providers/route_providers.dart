import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/routing/data/datasources/valhalla_route_datasource.dart';
import 'package:rihla/features/routing/data/repositories/route_repository_impl.dart';
import 'package:rihla/features/routing/data/services/mock_route_service.dart';
import 'package:rihla/features/routing/data/services/valhalla_route_service.dart';
import 'package:rihla/features/routing/domain/entities/route_point.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/errors/route_failure.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/domain/repositories/route_repository.dart';
import 'package:rihla/features/routing/domain/services/route_service.dart';

/// Provides the Valhalla-backed [RouteService].
final routeServiceProvider = Provider<RouteService>((ref) {
  final datasource = ValhallaRouteDatasource();
  ref.onDispose(datasource.dispose);
  return ValhallaRouteService(datasource);
});

/// Mock route service for development and tests.
final mockRouteServiceProvider = Provider<RouteService>(
  (ref) => MockRouteService(simulatedDelay: Duration.zero),
);

final routeRepositoryProvider = Provider<RouteRepository>(
  (ref) => RouteRepositoryImpl(ref.watch(routeServiceProvider)),
);

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
    try {
      final result = await ref.read(routeRepositoryProvider).getRoutes(request);
      state = RouteReady(result);
    } on RouteFailure catch (failure) {
      state = RouteError(failure);
    } catch (e) {
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
    if (current is! RouteReady) return;
    RouteSummary? selected;
    for (final r in current.result.routes) {
      if (r.id == routeId) {
        selected = r;
        break;
      }
    }
    if (selected == null) return;
    state = RouteSelected(result: current.result, selected: selected);
  }

  Future<void> retry() async {
    final request = _lastRequest;
    if (request != null) await fetchRoutes(request);
  }

  void clear() {
    _lastRequest = null;
    state = const RouteIdle();
  }

  RoutePoint _pointFromEndpoint(JourneyEndpoint endpoint) => RoutePoint(
        id: endpoint.id,
        name: endpoint.name,
        latitude: endpoint.latitude,
        longitude: endpoint.longitude,
      );
}
