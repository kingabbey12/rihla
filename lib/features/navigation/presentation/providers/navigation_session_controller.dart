import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/observability/analytics_event.dart';
import 'package:rihla/core/observability/breadcrumb.dart';
import 'package:rihla/core/observability/observability_providers.dart';
import 'package:rihla/core/observability/product_analytics.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_simulation.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/domain/models/reroute_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_infra.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/reroute_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/voice_guidance_providers.dart';
import 'package:rihla/features/navigation/presentation/services/navigation_polyline_sync.dart';
import 'package:rihla/features/navigation/presentation/services/navigation_tick_scheduler.dart';
import 'package:rihla/features/navigation/presentation/services/navigation_voice_coordinator.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/safety/presentation/providers/safety_providers.dart';

/// Central navigation session state machine.
final navigationSessionControllerProvider =
    NotifierProvider<NavigationSessionController, NavigationSessionState>(
  NavigationSessionController.new,
);

class NavigationSessionController extends Notifier<NavigationSessionState> {
  int _tickCount = 0;
  bool _simulateOffRoute = false;
  bool _pausedForLifecycle = false;

  static const _baseTickInterval = Duration(seconds: 3);

  NavigationTickScheduler get _scheduler =>
      ref.read(navigationTickSchedulerProvider);

  NavigationVoiceCoordinator get _voice =>
      ref.read(navigationVoiceCoordinatorProvider);

  NavigationPolylineSync get _polyline =>
      ref.read(navigationPolylineSyncProvider);

  @override
  NavigationSessionState build() {
    final stored = ref.read(navigationSessionRepositoryProvider).current;
    if (stored != null &&
        (stored.status == NavigationStatus.navigating ||
            stored.status == NavigationStatus.paused ||
            stored.status == NavigationStatus.rerouting)) {
      return NavigationSessionActive(stored);
    }
    return const NavigationSessionInactive();
  }

  Duration _tickIntervalFor(NavigationSession session) {
    final multiplier = session.simulation.speedMultiplier.clamp(0.5, 8.0);
    return Duration(
      milliseconds: (_baseTickInterval.inMilliseconds / multiplier).round(),
    );
  }

  Future<void> _persist(NavigationSession session) async {
    await ref.read(navigationSessionRepositoryProvider).save(session);
    if (!ref.mounted) return;
    state = NavigationSessionActive(session);
  }

  void _startTicking(NavigationSession session) {
    _scheduler.scheduleIfNeeded(
      _tickIntervalFor(session),
      _onTick,
    );
  }

  void _stopTicking() => _scheduler.cancel();

  Future<void> startSession({
    required JourneySummary journey,
    required RouteSummary route,
    bool simulationMode = false,
    bool voiceEnabled = true,
  }) async {
    _stopTicking();
    _tickCount = 0;
    _simulateOffRoute = false;
    _pausedForLifecycle = false;
    _voice.reset();
    // Continuous GPS updates for live navigation puck and turn-by-turn.
    await ref.read(locationControllerProvider.notifier).startForegroundStream();
    final sessionId = 'nav_${DateTime.now().millisecondsSinceEpoch}';
    final engine = ref.read(navigationSessionEngineProvider);
    var session = engine.createInitial(
      sessionId: sessionId,
      journey: journey,
      route: route,
      simulationMode: simulationMode,
      voiceEnabled: voiceEnabled,
    );
    session = await ref
        .read(safetySessionEnricherProvider)
        .enrich(session, tickCount: 0);
    await _persist(session);
    _polyline.setRoute(route);
    _startTicking(session);
    await _voice.announceIfNeeded(session);
    trackProductEvent(ref, AnalyticsEvent.journeyStarted);
    ref.read(appLoggerProvider).log(
      'journey_started',
      category: ObservabilityCategory.navigation,
      data: {'simulation': '$simulationMode'},
    );
  }

  Future<void> _onTick() async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    final session = current.session;
    if (session.simulation.playback != SimulationPlayback.playing) return;
    if (session.status == NavigationStatus.rerouting) return;

    _tickCount++;
    final engine = ref.read(navigationSessionEngineProvider);
    var updated = engine.advance(
      session: session,
      tickCount: _tickCount,
      gpsFix: session.simulationMode ? null : _currentGpsFix(),
      simulateOffRoute: _simulateOffRoute,
    );

    if (updated.isOffRoute && updated.rerouteState is RerouteIdle) {
      updated = await ref
          .read(safetySessionEnricherProvider)
          .enrich(updated, tickCount: _tickCount);
      await _handleReroute(updated);
      return;
    }

    updated = await ref
        .read(safetySessionEnricherProvider)
        .enrich(updated, tickCount: _tickCount);
    await _persist(updated);
    _startTicking(updated);
    await _voice.announceIfNeeded(updated);

    if (updated.hasArrived) {
      _stopTicking();
      trackProductEvent(ref, AnalyticsEvent.journeyCompleted);
      ref.read(appLoggerProvider).log(
        'journey_completed',
        category: ObservabilityCategory.navigation,
      );
    }
  }

  Future<void> _handleReroute(NavigationSession session) async {
    final reroute = ref.read(rerouteControllerProvider);
    var working = session.copyWith(
      status: NavigationStatus.rerouting,
      lastUpdatedAt: DateTime.now(),
    );
    working = reroute.markRequested(working);
    await _persist(working);

    final result = await reroute.recalculate(working);
    if (result.route != null) {
      await applyReroutedRoute(result.route!);
    } else {
      await _persist(
        working.copyWith(
          status: NavigationStatus.navigating,
          rerouteState: result.state,
          lastUpdatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> retryReroute() async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    await ref.read(rerouteControllerProvider).retryRecalculate(
          current.session,
          (_, route) => applyReroutedRoute(route),
          (session, failureState) => _persist(
            session.copyWith(
              status: NavigationStatus.navigating,
              rerouteState: failureState,
              lastUpdatedAt: DateTime.now(),
            ),
          ),
        );
  }

  Future<void> applyReroutedRoute(RouteSummary newRoute) async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    final engine = ref.read(navigationSessionEngineProvider);
    final rebuilt = engine.createInitial(
      sessionId: current.session.sessionId,
      journey: current.session.journey,
      route: newRoute,
      simulationMode: current.session.simulationMode,
      voiceEnabled: current.session.voiceEnabled,
    );
    final resumed = await ref.read(safetySessionEnricherProvider).enrich(
          rebuilt.copyWith(
            simulation: current.session.simulation,
            rerouteState: RerouteSucceeded(newRoute),
            isOffRoute: false,
            status: NavigationStatus.navigating,
            lastUpdatedAt: DateTime.now(),
          ),
          tickCount: 0,
        );
    _tickCount = 0;
    _simulateOffRoute = false;
    await _persist(resumed.copyWith(rerouteState: const RerouteIdle()));
    _polyline.setRoute(newRoute);
    _startTicking(resumed);
  }

  Future<void> stopSession() async {
    final current = state;
    final wasNavigating = current is NavigationSessionActive &&
        !current.session.hasArrived;
    _stopTicking();
    _tickCount = 0;
    _simulateOffRoute = false;
    _pausedForLifecycle = false;
    await _voice.clearQueue();
    if (!ref.mounted) return;
    _polyline.clear();
    await ref.read(navigationSessionRepositoryProvider).clear();
    if (!ref.mounted) return;
    state = const NavigationSessionInactive();
    if (wasNavigating) {
      trackProductEvent(ref, AnalyticsEvent.navigationCancelled);
      ref.read(appLoggerProvider).log(
        'navigation_cancelled',
        category: ObservabilityCategory.navigation,
      );
    }
  }

  Future<void> pauseForLifecycle() async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    if (current.session.status != NavigationStatus.navigating) return;
    _pausedForLifecycle = true;
    await pauseSession();
  }

  Future<void> resumeFromLifecycle() async {
    if (!_pausedForLifecycle) return;
    _pausedForLifecycle = false;
    await resumeSession();
  }

  Future<void> pauseSession() async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    _stopTicking();
    final paused = current.session.copyWith(
      status: NavigationStatus.paused,
      simulation: current.session.simulation.copyWith(
        playback: SimulationPlayback.paused,
      ),
      lastUpdatedAt: DateTime.now(),
    );
    await _persist(paused);
  }

  Future<void> resumeSession() async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    final resumed = current.session.copyWith(
      status: NavigationStatus.navigating,
      simulation: current.session.simulation.copyWith(
        playback: SimulationPlayback.playing,
      ),
      lastUpdatedAt: DateTime.now(),
    );
    await _persist(resumed);
    _startTicking(resumed);
  }

  Future<void> playSimulation() async {
    await _setSimulationPlayback(SimulationPlayback.playing);
  }

  Future<void> pauseSimulation() async => pauseSession();

  Future<void> resumeSimulation() async => resumeSession();

  Future<void> setSimulationSpeed(double multiplier) async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    final updated = current.session.copyWith(
      simulation: current.session.simulation.copyWith(
        speedMultiplier: multiplier.clamp(0.5, 8.0),
      ),
      lastUpdatedAt: DateTime.now(),
    );
    await _persist(updated);
    if (updated.simulation.playback == SimulationPlayback.playing) {
      _startTicking(updated);
    }
  }

  Future<void> _setSimulationPlayback(SimulationPlayback playback) async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    final updated = current.session.copyWith(
      status: playback == SimulationPlayback.playing
          ? NavigationStatus.navigating
          : NavigationStatus.paused,
      simulation: current.session.simulation.copyWith(playback: playback),
      lastUpdatedAt: DateTime.now(),
    );
    await _persist(updated);
    if (playback == SimulationPlayback.playing) {
      _startTicking(updated);
    } else {
      _stopTicking();
    }
  }

  Future<void> simulateDeviation() async {
    _simulateOffRoute = true;
    await _scheduler.runOnce(_onTick);
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    final voice = ref.read(voiceGuidanceServiceProvider);
    if (enabled) {
      await voice.unmute();
    } else {
      await voice.mute();
    }
    final updated = current.session.copyWith(
      voiceEnabled: enabled,
      lastUpdatedAt: DateTime.now(),
    );
    await _persist(updated);
  }

  Future<void> setSimulationMode(bool enabled) async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    final updated = current.session.copyWith(
      simulationMode: enabled,
      lastUpdatedAt: DateTime.now(),
    );
    await _persist(updated);
  }

  LocationPosition? _currentGpsFix() {
    final loc = ref.read(locationControllerProvider);
    return switch (loc) {
      LocationActive(:final position) => position,
      _ => null,
    };
  }

  NavigationSession? get activeSession => switch (state) {
        NavigationSessionActive(:final session) => session,
        _ => null,
      };
}
