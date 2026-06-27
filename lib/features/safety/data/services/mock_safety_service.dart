import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/safety/data/services/weighted_safety_engine.dart';
import 'package:rihla/features/safety/domain/entities/hazard.dart';
import 'package:rihla/features/safety/domain/entities/hazard_severity.dart';
import 'package:rihla/features/safety/domain/entities/hazard_type.dart';
import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';
import 'package:rihla/features/safety/domain/services/safety_engine.dart';
import 'package:rihla/features/safety/domain/services/safety_service.dart';

/// Mock safety evaluation using session context and tick-based drift.
class MockSafetyService implements SafetyService {
  MockSafetyService({SafetyEngine? engine})
      : _engine = engine ?? WeightedSafetyEngine();

  final SafetyEngine _engine;

  @override
  Future<SafetySnapshot> evaluate(
    NavigationSession session, {
    int tickCount = 0,
  }) async {
    final progress = session.routeProgressPercent / 100;
    final speedFactor = (session.speedKmh / 120).clamp(0.0, 1.0);
    final offRoutePenalty = session.isOffRoute ? 15.0 : 0.0;

    final roadSafety =
        (85 - tickCount * 1.5 - offRoutePenalty).clamp(40.0, 95.0);
    final trafficRisk =
        (20 + tickCount * 2.5 + speedFactor * 20).clamp(10.0, 90.0);
    final weatherRisk = tickCount.isEven ? 18.0 : 35.0;
    final driverAlertness =
        (88 - speedFactor * 15 - tickCount * 0.5).clamp(50.0, 95.0);
    final vehicleReadiness =
        (90 - progress * 5).clamp(60.0, 95.0);
    final journeyRisk =
        (trafficRisk * 0.4 + weatherRisk * 0.3 + offRoutePenalty).clamp(
      10.0,
      95.0,
    );

    final assessment = _engine.compute(
      roadSafety: roadSafety,
      trafficRisk: trafficRisk,
      weatherRisk: weatherRisk,
      driverAlertness: driverAlertness,
      vehicleReadiness: vehicleReadiness,
      journeyRisk: journeyRisk,
      timestamp: DateTime.now(),
    );

    final hazards = _hazardsFor(session, tickCount);
    final primary = _primaryAlert(hazards);

    return SafetySnapshot(
      assessment: assessment,
      hazards: hazards,
      primaryAlert: primary,
    );
  }

  List<Hazard> _hazardsFor(NavigationSession session, int tickCount) {
    final now = DateTime.now();
    final remaining = session.remainingDistanceKm;
  final base = [
      Hazard(
        id: 'hz_speed_$tickCount',
        type: HazardType.speedCamera,
        severity: HazardSeverity.moderate,
        title: 'Speed camera ahead',
        description: 'Fixed speed camera on ${session.currentRoad}',
        distanceAheadKm: (remaining * 0.3).clamp(0.2, remaining),
        reportedAt: now,
      ),
      Hazard(
        id: 'hz_curve',
        type: HazardType.sharpCurve,
        severity: HazardSeverity.low,
        title: 'Sharp curve',
        description: 'Reduce speed before the bend',
        distanceAheadKm: (remaining * 0.45).clamp(0.3, remaining),
        reportedAt: now,
      ),
      Hazard(
        id: 'hz_school',
        type: HazardType.schoolZone,
        severity: HazardSeverity.moderate,
        title: 'School zone',
        description: 'Watch for pedestrians — speed limit reduced',
        distanceAheadKm: (remaining * 0.6).clamp(0.4, remaining),
        reportedAt: now,
      ),
    ];

    if (tickCount >= 2) {
      base.add(
        Hazard(
          id: 'hz_construction',
          type: HazardType.construction,
          severity: HazardSeverity.high,
          title: 'Road construction',
          description: 'Lane closure reported ahead',
          distanceAheadKm: (remaining * 0.25).clamp(0.15, remaining),
          reportedAt: now,
        ),
      );
    }
    if (tickCount >= 4) {
      base.add(
        Hazard(
          id: 'hz_rain',
          type: HazardType.heavyRain,
          severity: HazardSeverity.moderate,
          title: 'Heavy rain area',
          description: 'Reduced visibility expected',
          distanceAheadKm: (remaining * 0.15).clamp(0.1, remaining),
          reportedAt: now,
        ),
      );
    }
    if (session.isOffRoute) {
      base.add(
        Hazard(
          id: 'hz_custom',
          type: HazardType.custom,
          severity: HazardSeverity.critical,
          title: 'Off route',
          description: 'You have left the planned corridor',
          distanceAheadKm: 0,
          reportedAt: now,
          customLabel: 'Route deviation',
        ),
      );
    }
    if (tickCount >= 6) {
      base.add(
        Hazard(
          id: 'hz_accident',
          type: HazardType.accident,
          severity: HazardSeverity.critical,
          title: 'Accident reported',
          description: 'Emergency services on scene — expect delays',
          distanceAheadKm: (remaining * 0.12).clamp(0.05, remaining),
          reportedAt: now,
        ),
      );
    }

    base.sort((a, b) => a.distanceAheadKm.compareTo(b.distanceAheadKm));
    return base;
  }

  Hazard? _primaryAlert(List<Hazard> hazards) {
    if (hazards.isEmpty) return null;
    final active = hazards.where((h) => h.isActive).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) {
      final sev = b.severity.index.compareTo(a.severity.index);
      if (sev != 0) return sev;
      return a.distanceAheadKm.compareTo(b.distanceAheadKm);
    });
    return active.first;
  }
}
