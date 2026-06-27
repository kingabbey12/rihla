import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/models/ai_journey_summary.dart';

/// Contract for AI-powered journey recommendations.
///
/// Implementations may call OpenAI or other providers. Phase 5 uses mocks.
abstract class AiRecommendationService {
  Future<AiJourneySummary> generateSummary({
    required JourneyEndpoint origin,
    required JourneyEndpoint destination,
    required double distanceKm,
    required int durationMinutes,
    required double journeyScore,
    required double safetyScore,
  });
}
