import 'package:rihla/config/api_config.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_message.dart';
import 'package:rihla/features/ai_copilot/domain/services/llm_provider.dart';
import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/models/ai_journey_summary.dart';
import 'package:rihla/features/journey/domain/services/ai_recommendation_service.dart';

/// Production AI journey recommendations using live LLM context when available.
///
/// When OpenAI is not configured, returns a factual summary derived only from
/// the supplied metrics — never hardcoded demo highlights.
class LiveAiRecommendationService implements AiRecommendationService {
  LiveAiRecommendationService({LLMProvider? llmProvider})
      : _llm = llmProvider;

  final LLMProvider? _llm;

  @override
  Future<AiJourneySummary> generateSummary({
    required JourneyEndpoint origin,
    required JourneyEndpoint destination,
    required double distanceKm,
    required int durationMinutes,
    required double journeyScore,
    required double safetyScore,
  }) async {
    final llm = _llm;
    if (llm != null && llm.isEnabled && ApiConfig.aiEnabled) {
      try {
        final completion = await llm.complete(
          LlmRequest(
            mode: AiCopilotMode.journeyAdvisor,
            systemPrompt:
                'You are Rihla, a premium navigation assistant. '
                'Summarise the journey using only the provided facts. '
                'Be concise. Do not invent traffic, weather, or places.',
            messages: [
              AiMessage.user(
                'Origin: ${origin.name} (${origin.latitude}, ${origin.longitude})\n'
                'Destination: ${destination.name} (${destination.latitude}, ${destination.longitude})\n'
                'Distance: ${distanceKm.toStringAsFixed(1)} km\n'
                'Duration: $durationMinutes min\n'
                'Journey score: ${journeyScore.round()}/100\n'
                'Safety score: ${safetyScore.round()}/100',
              ),
            ],
          ),
        );
        final text = completion.text.trim();
        if (text.isNotEmpty) {
          final lines = text.split('\n').where((l) => l.trim().isNotEmpty);
          final headline = lines.first.trim();
          final body = lines.skip(1).join(' ').trim();
          return AiJourneySummary(
            headline: headline,
            body: body.isEmpty ? headline : body,
            highlights: const [],
          );
        }
      } catch (_) {
        // Fall through to factual summary.
      }
    }

    return _factualSummary(
      destination: destination,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      journeyScore: journeyScore,
      safetyScore: safetyScore,
    );
  }

  AiJourneySummary _factualSummary({
    required JourneyEndpoint destination,
    required double distanceKm,
    required int durationMinutes,
    required double journeyScore,
    required double safetyScore,
  }) {
    final quality = journeyScore >= 75
        ? 'favourable'
        : journeyScore >= 55
            ? 'moderate'
            : 'challenging';

    return AiJourneySummary(
      headline: 'Journey to ${destination.name}',
      body:
          'This ${distanceKm.toStringAsFixed(1)} km trip is estimated at '
          '$durationMinutes minutes based on current conditions. '
          'Overall conditions look $quality (score ${journeyScore.round()}/100, '
          'safety ${safetyScore.round()}/100).',
      highlights: const [],
    );
  }
}
