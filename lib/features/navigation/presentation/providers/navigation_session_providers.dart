import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/navigation/data/repositories/navigation_session_repository_impl.dart';
import 'package:rihla/features/navigation/data/services/mock_navigation_session_engine.dart';
import 'package:rihla/features/navigation/data/services/polyline_maneuver_engine.dart';
import 'package:rihla/features/navigation/data/services/polyline_route_deviation_detector.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_simulation.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/domain/models/reroute_state.dart';
import 'package:rihla/features/navigation/domain/repositories/navigation_session_repository.dart';
import 'package:rihla/features/navigation/domain/services/maneuver_engine.dart';
import 'package:rihla/features/navigation/domain/services/navigation_session_engine.dart';
import 'package:rihla/features/navigation/domain/services/route_deviation_detector.dart';
import 'package:rihla/features/navigation/presentation/providers/reroute_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/voice_guidance_providers.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';

final maneuverEngineProvider = Provider<ManeuverEngine>(
  (ref) => PolylineManeuverEngine(),
);

final routeDeviationDetectorProvider = Provider<RouteDeviationDetector>(
  (ref) => PolylineRouteDeviationDetector(),
);

final navigationSessionEngineProvider = Provider<NavigationSessionEngine>(
  (ref) => MockNavigationSessionEngine(
    maneuverEngine: ref.watch(maneuverEngineProvider),
    deviationDetector: ref.watch(routeDeviationDetectorProvider),
  ),
);

final navigationSessionRepositoryProvider = Provider<NavigationSessionRepository>(
  (ref) => NavigationSessionRepositoryImpl(),
);

/// Central navigation session state machine.
final navigationSessionControllerProvider =
    NotifierProvider<NavigationSessionController, NavigationSessionState>(
  NavigationSessionController.new,
);

class NavigationSessionController extends Notifier<NavigationSessionState> {
  Timer? _timer;
  int _tickCount = 0;
  bool _simulateOffRoute = false;
  String? _lastSpokenInstruction;

  static const _baseTickInterval = Duration(seconds: 3);

  @override
  NavigationSessionState build() {
    ref.onDispose(_disposeTimer);
    final stored = ref.read(navigationSessionRepositoryProvider).current;
    if (stored != null &&
        (stored.status == NavigationStatus.navigating ||
            stored.status == NavigationStatus.paused ||
            stored.status == NavigationStatus.rerouting)) {
      return NavigationSessionActive(stored);
    }
    return const NavigationSessionInactive();
  }

  void _disposeTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Duration _tickIntervalFor(NavigationSession session) {
    final multiplier = session.simulation.speedMultiplier.clamp(0.5, 8.0);
    return Duration(
      milliseconds: (_baseTickInterval.inMilliseconds / multiplier).round(),
    );
  }

  void _scheduleTimer(NavigationSession session) {
    _disposeTimer();
    _timer = Timer.periodic(_tickIntervalFor(session), (_) => _onTick());
  }

  Future<void> _persist(NavigationSession session) async {
    await ref.read(navigationSessionRepositoryProvider).save(session);
    state = NavigationSessionActive(session);
  }

  /// Begins a new navigation session for [journey] on [route].
  Future<void> startSession({
    required JourneySummary journey,
    required RouteSummary route,
    bool simulationMode = true,
    bool voiceEnabled = false,
  }) async {
    _disposeTimer();
    _tickCount = 0;
    _simulateOffRoute = false;
    _lastSpokenInstruction = null;
    final sessionId = 'nav_${DateTime.now().millisecondsSinceEpoch}';
    final engine = ref.read(navigationSessionEngineProvider);
    final session = engine.createInitial(
      sessionId: sessionId,
      journey: journey,
      route: route,
      simulationMode: simulationMode,
      voiceEnabled: voiceEnabled,
    );
    await _persist(session);
    ref.read(mapRoutePolylineProvider.notifier).set(route.coordinates);
    _scheduleTimer(session);
    await _announceManeuver(session);
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
      simulateOffRoute: _simulateOffRoute,
    );

    if (updated.isOffRoute && updated.rerouteState is RerouteIdle) {
      await _handleReroute(updated);
      return;
    }

    await _persist(updated);
    _scheduleTimer(updated);
    await _announceManeuver(updated);

    if (updated.hasArrived) {
      _disposeTimer();
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

  Future<void> _announceManeuver(NavigationSession session) async {
    if (!session.voiceEnabled) return;
    final instruction = session.currentManeuver.instruction;
    if (instruction == _lastSpokenInstruction) return;
    _lastSpokenInstruction = instruction;
    final voice = ref.read(voiceGuidanceServiceProvider);
    if (voice.isMuted) {
      await voice.unmute();
    }
    await voice.speak(instruction, languageCode: 'en');
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
    final resumed = rebuilt.copyWith(
      simulation: current.session.simulation,
      rerouteState: RerouteSucceeded(newRoute),
      isOffRoute: false,
      status: NavigationStatus.navigating,
      lastUpdatedAt: DateTime.now(),
    );
    _tickCount = 0;
    _simulateOffRoute = false;
    await _persist(resumed.copyWith(rerouteState: const RerouteIdle()));
    ref.read(mapRoutePolylineProvider.notifier).set(newRoute.coordinates);
    _scheduleTimer(resumed);
  }

  Future<void> stopSession() async {
    _disposeTimer();
    _tickCount = 0;
    _simulateOffRoute = false;
    _lastSpokenInstruction = null;
    await ref.read(voiceGuidanceServiceProvider).clearQueue();
    await ref.read(navigationSessionRepositoryProvider).clear();
    state = const NavigationSessionInactive();
  }

  Future<void> pauseSession() async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    _disposeTimer();
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
    _scheduleTimer(resumed);
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
      _scheduleTimer(updated);
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
      _scheduleTimer(updated);
    } else {
      _disposeTimer();
    }
  }

  Future<void> simulateDeviation() async {
    _simulateOffRoute = true;
    await _onTick();
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

  NavigationSession? get activeSession => switch (state) {
        NavigationSessionActive(:final session) => session,
        _ => null,
      };
}

NavigationSession? _activeSession(NavigationSessionState state) =>
    state is NavigationSessionActive ? state.session : null;

final navigationSessionProvider = Provider<NavigationSession?>((ref) {
  return _activeSession(ref.watch(navigationSessionControllerProvider));
});

final navigationSessionIdProvider = Provider<String?>((ref) {
  return ref.watch(navigationSessionProvider)?.sessionId;
});

final navigationSessionStatusProvider = Provider<NavigationStatus?>((ref) {
  return ref.watch(navigationSessionProvider)?.status;
});

final navigationCurrentPositionProvider = Provider((ref) {
  return ref.watch(navigationSessionProvider)?.currentPosition;
});

final navigationCurrentRoadProvider = Provider<String?>((ref) {
  return ref.watch(navigationSessionProvider)?.currentRoad;
});

final navigationCurrentManeuverProvider = Provider((ref) {
  return ref.watch(navigationSessionProvider)?.currentManeuver;
});

final navigationRemainingDistanceProvider = Provider<double?>((ref) {
  return ref.watch(navigationSessionProvider)?.remainingDistanceKm;
});

final navigationDistanceTraveledProvider = Provider<double?>((ref) {
  return ref.watch(navigationSessionProvider)?.distanceTraveledKm;
});

final navigationRemainingDurationProvider = Provider<Duration?>((ref) {
  return ref.watch(navigationSessionProvider)?.remainingDuration;
});

final navigationEtaProvider = Provider<DateTime?>((ref) {
  return ref.watch(navigationSessionProvider)?.eta;
});

final navigationSpeedProvider = Provider<double?>((ref) {
  return ref.watch(navigationSessionProvider)?.speedKmh;
});

final navigationHeadingProvider = Provider<double?>((ref) {
  return ref.watch(navigationSessionProvider)?.headingDegrees;
});

final navigationRouteProgressProvider = Provider<double?>((ref) {
  return ref.watch(navigationSessionProvider)?.routeProgressPercent;
});

final navigationVoiceEnabledProvider = Provider<bool?>((ref) {
  return ref.watch(navigationSessionProvider)?.voiceEnabled;
});

final navigationSimulationModeProvider = Provider<bool?>((ref) {
  return ref.watch(navigationSessionProvider)?.simulationMode;
});

final navigationSimulationProvider = Provider<NavigationSimulation?>((ref) {
  return ref.watch(navigationSessionProvider)?.simulation;
});

final navigationLaneGuidanceProvider = Provider((ref) {
  return ref.watch(navigationSessionProvider)?.laneGuidance;
});

final navigationSpeedLimitProvider = Provider((ref) {
  return ref.watch(navigationSessionProvider)?.speedLimit;
});

final navigationRerouteStateProvider = Provider<RerouteState?>((ref) {
  return ref.watch(navigationSessionProvider)?.rerouteState;
});

final navigationIsOffRouteProvider = Provider<bool?>((ref) {
  return ref.watch(navigationSessionProvider)?.isOffRoute;
});

final navigationNextRoadProvider = Provider<String?>((ref) {
  return ref.watch(navigationSessionProvider)?.currentManeuver.nextRoad;
});
