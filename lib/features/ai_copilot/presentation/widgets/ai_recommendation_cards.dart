import 'package:flutter/material.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation.dart';
import 'package:rihla/features/ai_copilot/presentation/extensions/ai_recommendation_l10n.dart';

/// Animated, premium list of AI recommendation cards with staggered entrance.
class AiRecommendationCards extends StatelessWidget {
  const AiRecommendationCards({
    required this.recommendations,
    super.key,
    this.onAction,
  });

  final List<AiRecommendation> recommendations;
  final void Function(AiRecommendation recommendation)? onAction;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < recommendations.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Card(
              recommendation: recommendations[i],
              index: i,
              onAction: onAction,
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.recommendation,
    required this.index,
    this.onAction,
  });

  final AiRecommendation recommendation;
  final int index;
  final void Function(AiRecommendation recommendation)? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = recommendation.type.color(theme);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + index * 110),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(recommendation.type.icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recommendation.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (recommendation.actionable && onAction != null)
              IconButton(
                icon: Icon(Icons.arrow_forward_rounded, color: color),
                onPressed: () => onAction!(recommendation),
              ),
          ],
        ),
      ),
    );
  }
}
