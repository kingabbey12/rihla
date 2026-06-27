import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Lifecycle of an automatic reroute attempt.
sealed class RerouteState {
  const RerouteState();
}

final class RerouteIdle extends RerouteState {
  const RerouteIdle();
}

final class RerouteRequested extends RerouteState {
  const RerouteRequested();
}

final class RerouteInProgress extends RerouteState {
  const RerouteInProgress({this.attempt = 1});

  final int attempt;
}

final class RerouteSucceeded extends RerouteState {
  const RerouteSucceeded(this.newRoute);

  final RouteSummary newRoute;
}

final class RerouteFailed extends RerouteState {
  const RerouteFailed(this.message, {this.canRetry = true});

  final String message;
  final bool canRetry;
}
