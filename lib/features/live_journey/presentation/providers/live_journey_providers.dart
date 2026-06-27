import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/live_journey/data/mappers/live_journey_session_metrics_mapper.dart';
import 'package:rihla/features/live_journey/data/services/mock_journey_metrics_engine.dart';
import 'package:rihla/features/live_journey/domain/entities/dashboard_display_mode.dart';
import 'package:rihla/features/live_journey/domain/entities/journey_metric.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/domain/services/journey_metrics_engine.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';

final journeyMetricsEngineProvider = Provider<JourneyMetricsEngine>(
  (ref) => MockJourneyMetricsEngine(),
);

final liveJourneySessionMetricsMapperProvider =
    Provider<LiveJourneySessionMetricsMapper>(
  (ref) => const LiveJourneySessionMetricsMapper(),
);

/// Central live journey state — drives the dashboard from the navigation session.
final liveJourneyControllerProvider =
    NotifierProvider<LiveJourneyController, LiveJourneyState>(
  LiveJourneyController.new,
);

class LiveJourneyController extends Notifier<LiveJourneyState> {
  int _ambientTickCount = 0;
  DashboardDisplayMode _displayMode = DashboardDisplayMode.collapsed;
  DateTime? _lastSessionUpdate;

  @override
  LiveJourneyState build() {
    final navState = ref.watch(navigationSessionControllerProvider);
    if (navState is! NavigationSessionActive) {
      _ambientTickCount = 0;
      _lastSessionUpdate = null;
      return const LiveJourneyInactive();
    }

    final session = navState.session;
    if (_lastSessionUpdate != session.lastUpdatedAt) {
      _ambientTickCount++;
      _lastSessionUpdate = session.lastUpdatedAt;
    }

    return _composeActiveState(session);
  }

  LiveJourneyActive _composeActiveState(NavigationSession session) {
    final engine = ref.read(journeyMetricsEngineProvider);
    final mapper = ref.read(liveJourneySessionMetricsMapperProvider);
    final ambient = engine.ambientMetrics(
      route: session.route,
      tickCount: _ambientTickCount,
      progressPercent: session.routeProgressPercent,
    );
    final metrics = mapper.compose(session: session, ambient: ambient);

    return LiveJourneyActive(
      route: session.route,
      metrics: metrics,
      displayMode: _displayMode,
      startedAt: session.startedAt,
      progressPercent: session.routeProgressPercent,
    );
  }

  void stop() {
    _ambientTickCount = 0;
    _lastSessionUpdate = null;
    _displayMode = DashboardDisplayMode.collapsed;
    state = const LiveJourneyInactive();
  }

  void setDisplayMode(DashboardDisplayMode mode) {
    _displayMode = mode;
    final navState = ref.read(navigationSessionControllerProvider);
    if (navState is NavigationSessionActive) {
      state = _composeActiveState(navState.session);
    }
  }

  void cycleDisplayMode() {
    final next = switch (_displayMode) {
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
