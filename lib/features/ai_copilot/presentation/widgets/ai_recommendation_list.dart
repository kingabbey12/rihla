import 'package:flutter/material.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation.dart';
import 'package:rihla/features/ai_copilot/presentation/extensions/ai_recommendation_l10n.dart';

/// List of AI recommendations with optional action chips.
class AiRecommendationList extends StatelessWidget {
  const AiRecommendationList({
    required this.recommendations,
    this.onAction,
    super.key,
  });

  final List<AiRecommendation> recommendations;
  final void Function(AiRecommendation recommendation)? onAction;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rec in recommendations)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: Icon(rec.type.icon, color: rec.type.color(theme)),
                title: Text(
                  rec.title,
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(rec.body),
                trailing: rec.actionable && onAction != null
                    ? IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => onAction!(rec),
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
