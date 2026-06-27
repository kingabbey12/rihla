import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/safety/data/services/weighted_safety_engine.dart';
import 'package:rihla/features/safety/domain/entities/safety_score_weights.dart';

void main() {
  late WeightedSafetyEngine engine;

  setUp(() {
    engine = WeightedSafetyEngine();
  });

  test('compute produces weighted overall safety score', () {
    final assessment = engine.compute(
      roadSafety: 90,
      trafficRisk: 20,
      weatherRisk: 15,
      driverAlertness: 85,
      vehicleReadiness: 88,
      journeyRisk: 25,
    );

    expect(assessment.overallSafetyScore, greaterThan(70));
    expect(assessment.roadSafety, 90);
    expect(assessment.trafficRisk, 20);
    expect(assessment.journeyRisk, 25);
  });

  test('custom weights affect overall score', () {
    final defaultScore = engine.compute(
      roadSafety: 80,
      trafficRisk: 40,
      weatherRisk: 30,
      driverAlertness: 70,
      vehicleReadiness: 75,
      journeyRisk: 35,
    );

    final roadHeavy = engine.compute(
      roadSafety: 80,
      trafficRisk: 40,
      weatherRisk: 30,
      driverAlertness: 70,
      vehicleReadiness: 75,
      journeyRisk: 35,
      weights: const SafetyScoreWeights(
        roadSafety: 0.6,
        trafficRisk: 0.1,
        weatherRisk: 0.1,
        driverAlertness: 0.1,
        vehicleReadiness: 0.05,
        journeyRisk: 0.05,
      ),
    );

    expect(roadHeavy.overallSafetyScore, isNot(equals(defaultScore.overallSafetyScore)));
  });
}
