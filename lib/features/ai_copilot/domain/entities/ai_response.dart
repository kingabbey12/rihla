import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation.dart';

/// Structured output from the AI service.
class AiResponse {
  const AiResponse({
    required this.summary,
    required this.recommendations,
    required this.highlights,
    required this.generatedAt,
    this.fromMock = true,
  });

  final String summary;
  final List<AiRecommendation> recommendations;
  final List<String> highlights;
  final DateTime generatedAt;
  final bool fromMock;
}
