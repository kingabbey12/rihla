import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/navigation/data/repositories/navigation_session_repository_impl.dart';
import 'package:rihla/features/navigation/data/services/mock_navigation_session_engine.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/domain/repositories/navigation_session_repository.dart';
import 'package:rihla/features/navigation/domain/services/navigation_session_engine.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

final navigationSessionEngineProvider = Provider<NavigationSessionEngine>(
  (ref) => MockNavigationSessionEngine(),
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

  static const _tickInterval = Duration(seconds: 3);

  @override
  NavigationSessionState build() {
    ref.onDispose(_disposeTimer);
    final stored = ref.read(navigationSessionRepositoryProvider).current;
    if (stored != null && stored.status == NavigationStatus.navigating) {
      return NavigationSessionActive(stored);
    }
    return const NavigationSessionInactive();
  }

  void _disposeTimer() {
    _timer?.cancel();
    _timer = null;
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
    final sessionId = 'nav_${DateTime.now().millisecondsSinceEpoch}';
    final engine = ref.read(navigationSessionEngineProvider);
    final session = engine.createInitial(
      sessionId: sessionId,
      journey: journey,
      route: route,
      simulationMode: simulationMode,
      voiceEnabled: voiceEnabled,
    );
    await ref.read(navigationSessionRepositoryProvider).save(session);
    state = NavigationSessionActive(session);
    _timer = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  void _onTick() {
    final current = state;
    if (current is! NavigationSessionActive) return;

    _tickCount++;
    final engine = ref.read(navigationSessionEngineProvider);
    final updated = engine.advance(
      session: current.session,
      tickCount: _tickCount,
    );
    ref.read(navigationSessionRepositoryProvider).save(updated);
    state = NavigationSessionActive(updated);
  }

  Future<void> stopSession() async {
    _disposeTimer();
    _tickCount = 0;
    await ref.read(navigationSessionRepositoryProvider).clear();
    state = const NavigationSessionInactive();
  }

  Future<void> pauseSession() async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    _disposeTimer();
    final paused = current.session.copyWith(
      status: NavigationStatus.paused,
      lastUpdatedAt: DateTime.now(),
    );
    await ref.read(navigationSessionRepositoryProvider).save(paused);
    state = NavigationSessionActive(paused);
  }

  Future<void> resumeSession() async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    if (current.session.status != NavigationStatus.paused) return;
    final resumed = current.session.copyWith(
      status: NavigationStatus.navigating,
      lastUpdatedAt: DateTime.now(),
    );
    await ref.read(navigationSessionRepositoryProvider).save(resumed);
    state = NavigationSessionActive(resumed);
    _timer = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    final updated = current.session.copyWith(
      voiceEnabled: enabled,
      lastUpdatedAt: DateTime.now(),
    );
    await ref.read(navigationSessionRepositoryProvider).save(updated);
    state = NavigationSessionActive(updated);
  }

  Future<void> setSimulationMode(bool enabled) async {
    final current = state;
    if (current is! NavigationSessionActive) return;
    final updated = current.session.copyWith(
      simulationMode: enabled,
      lastUpdatedAt: DateTime.now(),
    );
    await ref.read(navigationSessionRepositoryProvider).save(updated);
    state = NavigationSessionActive(updated);
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
