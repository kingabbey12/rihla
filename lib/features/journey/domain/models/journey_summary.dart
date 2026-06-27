import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/entities/journey_metrics.dart';
import 'package:rihla/features/journey/domain/entities/journey_score.dart';
import 'package:rihla/features/journey/domain/models/ai_journey_summary.dart';

/// Complete journey preview shown on the Journey Card.
class JourneySummary {
  const JourneySummary({
    required this.destination,
    required this.origin,
    required this.metrics,
    required this.score,
    required this.aiSummary,
  });

  final JourneyEndpoint destination;
  final JourneyEndpoint origin;
  final JourneyMetrics metrics;
  final JourneyScore score;
  final AiJourneySummary aiSummary;
}
