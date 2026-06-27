import 'package:rihla/features/safety/domain/entities/safety_assessment.dart';
import 'package:rihla/features/safety/domain/entities/safety_score_weights.dart';
import 'package:rihla/features/safety/domain/services/safety_engine.dart';

/// Weighted safety score calculator.
class WeightedSafetyEngine implements SafetyEngine {
  @override
  SafetyAssessment compute({
    required double roadSafety,
    required double trafficRisk,
    required double weatherRisk,
    required double driverAlertness,
    required double vehicleReadiness,
    required double journeyRisk,
    SafetyScoreWeights? weights,
    DateTime? timestamp,
  }) {
    final w = weights ?? SafetyScoreWeights.defaultWeights;
    final trafficSafety = (100 - trafficRisk).clamp(0.0, 100.0);
    final weatherSafety = (100 - weatherRisk).clamp(0.0, 100.0);
    final journeySafety = (100 - journeyRisk).clamp(0.0, 100.0);

    final overall = (roadSafety * w.roadSafety +
            trafficSafety * w.trafficRisk +
            weatherSafety * w.weatherRisk +
            driverAlertness * w.driverAlertness +
            vehicleReadiness * w.vehicleReadiness +
            journeySafety * w.journeyRisk) /
        w.sum;

    return SafetyAssessment(
      overallSafetyScore: overall.clamp(0.0, 100.0),
      roadSafety: roadSafety.clamp(0.0, 100.0),
      trafficRisk: trafficRisk.clamp(0.0, 100.0),
      weatherRisk: weatherRisk.clamp(0.0, 100.0),
      driverAlertness: driverAlertness.clamp(0.0, 100.0),
      vehicleReadiness: vehicleReadiness.clamp(0.0, 100.0),
      journeyRisk: journeyRisk.clamp(0.0, 100.0),
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}
