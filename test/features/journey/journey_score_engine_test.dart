import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';
import 'package:rihla/features/journey/domain/services/journey_score_engine.dart';

void main() {
  group('JourneyScoreEngine', () {
    test('computes weighted journey score', () {
      const components = JourneyScoreComponents(
        safety: 80,
        traffic: 70,
        weather: 90,
        roadConditions: 75,
        fuelEfficiency: 85,
        vehicleStatus: 95,
      );
      final score = JourneyScoreEngine.compute(components);
      expect(score.journeyScore, greaterThan(70));
      expect(score.journeyScore, lessThanOrEqualTo(100));
    });

    test('safety score emphasises safety and road conditions', () {
      const highSafety = JourneyScoreComponents(
        safety: 100,
        traffic: 50,
        weather: 50,
        roadConditions: 100,
        fuelEfficiency: 50,
        vehicleStatus: 50,
      );
      const lowSafety = JourneyScoreComponents(
        safety: 30,
        traffic: 50,
        weather: 50,
        roadConditions: 30,
        fuelEfficiency: 50,
        vehicleStatus: 50,
      );
      final high = JourneyScoreEngine.compute(highSafety);
      final low = JourneyScoreEngine.compute(lowSafety);
      expect(high.safetyScore, greaterThan(low.safetyScore));
    });

    test('custom weights change journey score', () {
      const components = JourneyScoreComponents(
        safety: 100,
        traffic: 0,
        weather: 0,
        roadConditions: 0,
        fuelEfficiency: 0,
        vehicleStatus: 0,
      );
      final defaultScore = JourneyScoreEngine.compute(components);
      final safetyOnly = JourneyScoreEngine.compute(
        components,
        weights: {
          'safety': 1.0,
          'traffic': 0,
          'weather': 0,
          'roadConditions': 0,
          'fuelEfficiency': 0,
          'vehicleStatus': 0,
        },
      );
      expect(safetyOnly.journeyScore, 100);
      expect(defaultScore.journeyScore, closeTo(25, 0.01));
    });
  });
}
