import 'package:rihla/features/routing/domain/errors/route_failure.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Lifecycle state of the routing subsystem.
sealed class RouteState {
  const RouteState();
}

final class RouteIdle extends RouteState {
  const RouteIdle();
}

final class RouteLoading extends RouteState {
  const RouteLoading();
}

final class RouteReady extends RouteState {
  const RouteReady(this.result);

  final RouteResult result;
}

final class RouteSelected extends RouteState {
  const RouteSelected({
    required this.result,
    required this.selected,
  });

  final RouteResult result;
  final RouteSummary selected;
}

final class RouteError extends RouteState {
  const RouteError(this.failure);

  final RouteFailure failure;
}
