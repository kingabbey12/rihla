import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/safety/data/repositories/safety_repository_impl.dart';
import 'package:rihla/features/safety/data/services/mock_safety_service.dart';
import 'package:rihla/features/safety/data/services/weighted_safety_engine.dart';
import 'package:rihla/features/safety/domain/entities/hazard.dart';
import 'package:rihla/features/safety/domain/entities/hazard_severity.dart';
import 'package:rihla/features/safety/domain/entities/safety_assessment.dart';
import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';
import 'package:rihla/features/safety/domain/models/safety_state.dart';
import 'package:rihla/features/safety/domain/repositories/safety_repository.dart';
import 'package:rihla/features/safety/domain/services/safety_engine.dart';
import 'package:rihla/features/safety/domain/services/safety_service.dart';

final safetyEngineProvider = Provider<SafetyEngine>(
  (ref) => WeightedSafetyEngine(),
);

final safetyServiceProvider = Provider<SafetyService>(
  (ref) => MockSafetyService(engine: ref.watch(safetyEngineProvider)),
);

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => SafetyRepositoryImpl(),
);

/// Enriches navigation sessions with safety data without depending on
/// [safetyControllerProvider] (avoids circular dependency with navigation).
final safetySessionEnricherProvider = Provider<SafetySessionEnricher>(
  (ref) => SafetySessionEnricher(ref),
);

class SafetySessionEnricher {
  SafetySessionEnricher(this._ref);

  final Ref _ref;

  Future<NavigationSession> enrich(
    NavigationSession session, {
    required int tickCount,
  }) async {
    final snapshot = await _ref.read(safetyServiceProvider).evaluate(
          session,
          tickCount: tickCount,
        );
    await _ref.read(safetyRepositoryProvider).save(snapshot);
    return session.copyWith(safety: snapshot);
  }
}

/// Central safety state — mirrors the active session safety snapshot.
final safetyControllerProvider =
    NotifierProvider<SafetyController, SafetyState>(SafetyController.new);

class SafetyController extends Notifier<SafetyState> {
  @override
  SafetyState build() {
    ref.listen(navigationSessionControllerProvider, (previous, next) {
      if (next is NavigationSessionInactive) {
        ref.read(safetyRepositoryProvider).clear();
        state = const SafetyInactive();
      }
    });

    final session = ref.watch(navigationSessionProvider);
    if (session == null) return const SafetyInactive();
    return SafetyActive(session.safety);
  }
}

final safetySnapshotProvider = Provider<SafetySnapshot?>((ref) {
  return ref.watch(navigationSessionProvider)?.safety;
});

final safetyAssessmentProvider = Provider<SafetyAssessment?>((ref) {
  return ref.watch(safetySnapshotProvider)?.assessment;
});

final safetyOverallScoreProvider = Provider<double?>((ref) {
  return ref.watch(safetyAssessmentProvider)?.overallSafetyScore;
});

final safetyRoadSafetyProvider = Provider<double?>((ref) {
  return ref.watch(safetyAssessmentProvider)?.roadSafety;
});

final safetyTrafficRiskProvider = Provider<double?>((ref) {
  return ref.watch(safetyAssessmentProvider)?.trafficRisk;
});

final safetyWeatherRiskProvider = Provider<double?>((ref) {
  return ref.watch(safetyAssessmentProvider)?.weatherRisk;
});

final safetyDriverAlertnessProvider = Provider<double?>((ref) {
  return ref.watch(safetyAssessmentProvider)?.driverAlertness;
});

final safetyVehicleReadinessProvider = Provider<double?>((ref) {
  return ref.watch(safetyAssessmentProvider)?.vehicleReadiness;
});

final safetyJourneyRiskProvider = Provider<double?>((ref) {
  return ref.watch(safetyAssessmentProvider)?.journeyRisk;
});

final safetyHazardsProvider = Provider<List<Hazard>>((ref) {
  return ref.watch(safetySnapshotProvider)?.hazards ?? const [];
});

final safetyPrimaryAlertProvider = Provider<Hazard?>((ref) {
  return ref.watch(safetySnapshotProvider)?.primaryAlert;
});

final safetyHasCriticalAlertProvider = Provider<bool>((ref) {
  final alert = ref.watch(safetyPrimaryAlertProvider);
  if (alert == null) return false;
  return alert.severity == HazardSeverity.critical ||
      alert.severity == HazardSeverity.high;
});
