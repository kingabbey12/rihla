import 'package:rihla/features/safety/domain/entities/safety_assessment.dart';
import 'package:rihla/features/safety/domain/entities/safety_score_weights.dart';

/// Combines safety components into weighted overall scores.
abstract class SafetyEngine {
  SafetyAssessment compute({
    required double roadSafety,
    required double trafficRisk,
    required double weatherRisk,
    required double driverAlertness,
    required double vehicleReadiness,
    required double journeyRisk,
    SafetyScoreWeights? weights,
    DateTime? timestamp,
  });
}
