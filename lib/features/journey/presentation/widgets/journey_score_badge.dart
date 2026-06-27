import 'package:flutter/material.dart';

/// Circular score indicator for journey and safety ratings.
class JourneyScoreBadge extends StatelessWidget {
  const JourneyScoreBadge({
    required this.label,
    required this.score,
    required this.color,
    super.key,
  });

  final String label;
  final double score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = (score / 100).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: normalized,
                strokeWidth: 5,
                backgroundColor: color.withValues(alpha: 0.15),
                color: color,
              ),
              Text(
                score.round().toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
