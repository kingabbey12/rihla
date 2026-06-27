import 'package:rihla/features/journey/domain/entities/journey_score.dart';
import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';

/// Combines independent score components into overall journey and safety scores.
abstract final class JourneyScoreEngine {
  /// Computes weighted journey score and dedicated safety score.
  static JourneyScore compute(
    JourneyScoreComponents components, {
    Map<String, double>? weights,
  }) {
    final w = weights ?? JourneyScoreComponents.defaultWeights;
    final journeyScore = _weightedSum(components, w).clamp(0.0, 100.0);

    // Safety score emphasises the safety component but factors in road conditions.
    final safetyScore = (components.safety * 0.7 + components.roadConditions * 0.3)
        .clamp(0.0, 100.0);

    return JourneyScore(
      journeyScore: journeyScore,
      safetyScore: safetyScore,
      components: components,
    );
  }

  static double _weightedSum(
    JourneyScoreComponents c,
    Map<String, double> w,
  ) {
    return c.safety * w['safety']! +
        c.traffic * w['traffic']! +
        c.weather * w['weather']! +
        c.roadConditions * w['roadConditions']! +
        c.fuelEfficiency * w['fuelEfficiency']! +
        c.vehicleStatus * w['vehicleStatus']!;
  }
}
