import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/live_journey/data/services/mock_journey_metrics_engine.dart';
import 'package:rihla/features/live_journey/domain/entities/dashboard_display_mode.dart';
import 'package:rihla/features/live_journey/domain/entities/journey_metric.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/domain/services/journey_metrics_engine.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

final journeyMetricsEngineProvider = Provider<JourneyMetricsEngine>(
  (ref) => MockJourneyMetricsEngine(),
);

/// Central live journey state — drives the dashboard and metric providers.
final liveJourneyControllerProvider =
    NotifierProvider<LiveJourneyController, LiveJourneyState>(
  LiveJourneyController.new,
);

class LiveJourneyController extends Notifier<LiveJourneyState> {
  Timer? _timer;
  int _tickCount = 0;
  RouteSummary? _route;

  static const _tickInterval = Duration(seconds: 3);

  @override
  LiveJourneyState build() {
    ref.onDispose(_disposeTimer);
    return const LiveJourneyInactive();
  }

  void _disposeTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Starts live metric updates for the confirmed [route].
  void start(RouteSummary route) {
    _disposeTimer();
    _tickCount = 0;
    _route = route;
    final engine = ref.read(journeyMetricsEngineProvider);
    final metrics = engine.initialMetrics(route);
    state = LiveJourneyActive(
      route: route,
      metrics: metrics,
      displayMode: DashboardDisplayMode.collapsed,
      startedAt: DateTime.now(),
    );
    _timer = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  void _onTick() {
    final current = state;
    final route = _route;
    if (current is! LiveJourneyActive || route == null) return;

    _tickCount++;
    final engine = ref.read(journeyMetricsEngineProvider);
    final metrics = engine.tick(
      current: current.metrics,
      route: route,
      tickCount: _tickCount,
    );
    final remaining = metrics.remainingDistanceKm.value;
    final progress = route.distanceKm > 0
        ? ((route.distanceKm - remaining) / route.distanceKm * 100).clamp(0.0, 100.0)
        : 0.0;

    state = current.copyWith(
      metrics: metrics,
      progressPercent: progress,
    );
  }

  void stop() {
    _disposeTimer();
    _route = null;
    _tickCount = 0;
    state = const LiveJourneyInactive();
  }

  void setDisplayMode(DashboardDisplayMode mode) {
    final current = state;
    if (current is LiveJourneyActive) {
      state = current.copyWith(displayMode: mode);
    }
  }

  void cycleDisplayMode() {
    final current = state;
    if (current is! LiveJourneyActive) return;
    final next = switch (current.displayMode) {
      DashboardDisplayMode.collapsed => DashboardDisplayMode.expanded,
      DashboardDisplayMode.expanded => DashboardDisplayMode.floating,
      DashboardDisplayMode.floating => DashboardDisplayMode.collapsed,
    };
    setDisplayMode(next);
  }
}

LiveJourneyActive? _activeState(LiveJourneyState state) =>
    state is LiveJourneyActive ? state : null;

final liveJourneyScoreProvider = Provider<JourneyMetric<double>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.metrics
      .journeyScore;
});

final liveSafetyScoreProvider = Provider<JourneyMetric<double>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.metrics
      .safetyScore;
});

final liveTrafficScoreProvider = Provider<JourneyMetric<double>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.metrics
      .trafficScore;
});

final liveWeatherProvider = Provider<JourneyMetric<String>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.metrics
      .weather;
});

final liveRoadConditionProvider = Provider<JourneyMetric<String>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.metrics
      .roadCondition;
});

final liveCurrentSpeedProvider = Provider<JourneyMetric<double>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.metrics
      .currentSpeedKmh;
});

final liveEtaProvider = Provider<JourneyMetric<Duration>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))?.metrics.eta;
});

final liveRemainingDistanceProvider = Provider<JourneyMetric<double>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.metrics
      .remainingDistanceKm;
});

final liveFuelEstimateProvider = Provider<JourneyMetric<double>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.metrics
      .fuelEstimateLiters;
});

final liveBatteryEstimateProvider = Provider<JourneyMetric<double>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.metrics
      .batteryEstimatePercent;
});

final liveCurrentRoadNameProvider = Provider<JourneyMetric<String>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.metrics
      .currentRoadName;
});

final liveNextManeuverProvider = Provider<JourneyMetric<String>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.metrics
      .nextManeuver;
});

final liveArrivalTimeProvider = Provider<JourneyMetric<DateTime>?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.metrics
      .arrivalTime;
});

final liveJourneyProgressProvider = Provider<double?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))
      ?.progressPercent;
});

final liveDashboardDisplayModeProvider = Provider<DashboardDisplayMode?>((ref) {
  return _activeState(ref.watch(liveJourneyControllerProvider))?.displayMode;
});
