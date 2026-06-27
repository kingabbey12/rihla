import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation_type.dart';

/// A structured recommendation produced by the AI copilot.
class AiRecommendation {
  const AiRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.priority = 3,
    this.actionable = false,
  });

  final String id;
  final AiRecommendationType type;
  final String title;
  final String body;
  final int priority;
  final bool actionable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AiRecommendation && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
