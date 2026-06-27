import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/data/services/mock_reroute_service.dart';
import 'package:rihla/features/navigation/data/services/valhalla_reroute_service.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/models/reroute_state.dart';
import 'package:rihla/features/navigation/domain/services/reroute_service.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';

final mockRerouteServiceProvider = Provider<RerouteService>(
  (ref) => MockRerouteService(simulatedDelay: const Duration(milliseconds: 300)),
);

final rerouteServiceProvider = Provider<RerouteService>(
  (ref) => ValhallaRerouteService(ref.watch(routeServiceProvider)),
);

/// Orchestrates automatic rerouting when the driver leaves the corridor.
final rerouteControllerProvider = Provider<RerouteController>(
  (ref) => RerouteController(ref),
);

class RerouteController {
  RerouteController(this._ref);

  final Ref _ref;
  int _attempts = 0;
  static const _maxAttempts = 3;

  int get attempts => _attempts;

  NavigationSession markRequested(NavigationSession session) {
    _attempts++;
    return session.copyWith(
      rerouteState: RerouteInProgress(attempt: _attempts),
      lastUpdatedAt: DateTime.now(),
    );
  }

  Future<({RouteSummary? route, RerouteState state})> recalculate(
    NavigationSession session,
  ) async {
    try {
      final newRoute = await _ref.read(rerouteServiceProvider).recalculate(
            journey: session.journey,
            currentRoute: session.route,
          );
      _attempts = 0;
      return (route: newRoute, state: RerouteSucceeded(newRoute));
    } catch (e) {
      return (
        route: null,
        state: RerouteFailed(e.toString(), canRetry: _attempts < _maxAttempts),
      );
    }
  }

  Future<void> retryRecalculate(
    NavigationSession session,
    void Function(NavigationSession session, RouteSummary route) onSuccess,
    void Function(NavigationSession session, RerouteState state) onFailure,
  ) async {
    if (_attempts >= _maxAttempts) return;
    final marked = markRequested(session);
    final result = await recalculate(marked);
    if (result.route != null) {
      onSuccess(marked, result.route!);
    } else {
      onFailure(marked, result.state);
    }
  }
}
