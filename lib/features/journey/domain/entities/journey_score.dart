import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';

/// Computed journey and safety scores derived from [JourneyScoreComponents].
class JourneyScore {
  const JourneyScore({
    required this.journeyScore,
    required this.safetyScore,
    required this.components,
  });

  /// Overall journey quality 0–100.
  final double journeyScore;

  /// Dedicated safety rating 0–100 (derived primarily from safety component).
  final double safetyScore;

  final JourneyScoreComponents components;
}
