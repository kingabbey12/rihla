import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_simulation.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/domain/models/reroute_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_controller.dart';

NavigationSession? _activeSession(NavigationSessionState state) =>
    state is NavigationSessionActive ? state.session : null;

/// Active session — use field selectors below when possible.
final navigationSessionProvider = Provider<NavigationSession?>((ref) {
  return _activeSession(ref.watch(navigationSessionControllerProvider));
});

final navigationSessionIdProvider = Provider<String?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.sessionId : null,
    ),
  );
});

final navigationSessionStatusProvider = Provider<NavigationStatus?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.status : null,
    ),
  );
});

final navigationCurrentPositionProvider = Provider((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.currentPosition : null,
    ),
  );
});

final navigationCurrentRoadProvider = Provider<String?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.currentRoad : null,
    ),
  );
});

final navigationCurrentManeuverProvider = Provider((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.currentManeuver : null,
    ),
  );
});

final navigationRemainingDistanceProvider = Provider<double?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) =>
          s is NavigationSessionActive ? s.session.remainingDistanceKm : null,
    ),
  );
});

final navigationDistanceTraveledProvider = Provider<double?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) =>
          s is NavigationSessionActive ? s.session.distanceTraveledKm : null,
    ),
  );
});

final navigationRemainingDurationProvider = Provider<Duration?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) =>
          s is NavigationSessionActive ? s.session.remainingDuration : null,
    ),
  );
});

final navigationEtaProvider = Provider<DateTime?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.eta : null,
    ),
  );
});

final navigationSpeedProvider = Provider<double?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.speedKmh : null,
    ),
  );
});

final navigationHeadingProvider = Provider<double?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.headingDegrees : null,
    ),
  );
});

final navigationRouteProgressProvider = Provider<double?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) =>
          s is NavigationSessionActive ? s.session.routeProgressPercent : null,
    ),
  );
});

final navigationVoiceEnabledProvider = Provider<bool?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.voiceEnabled : null,
    ),
  );
});

final navigationSimulationModeProvider = Provider<bool?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.simulationMode : null,
    ),
  );
});

final navigationSimulationProvider = Provider<NavigationSimulation?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.simulation : null,
    ),
  );
});

final navigationLaneGuidanceProvider = Provider((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.laneGuidance : null,
    ),
  );
});

final navigationSpeedLimitProvider = Provider((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.speedLimit : null,
    ),
  );
});

final navigationRerouteStateProvider = Provider<RerouteState?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.rerouteState : null,
    ),
  );
});

final navigationIsOffRouteProvider = Provider<bool?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive ? s.session.isOffRoute : null,
    ),
  );
});

final navigationNextRoadProvider = Provider<String?>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) =>
          s is NavigationSessionActive ? s.session.currentManeuver.nextRoad : null,
    ),
  );
});

final navigationHasArrivedProvider = Provider<bool>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive && s.session.hasArrived,
    ),
  );
});

final navigationIsActiveProvider = Provider<bool>((ref) {
  return ref.watch(
    navigationSessionControllerProvider.select(
      (s) => s is NavigationSessionActive && !s.session.hasArrived,
    ),
  );
});
