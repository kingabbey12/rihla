import 'package:flutter/material.dart';

/// Circular safety score indicator.
class SafetyScoreRing extends StatelessWidget {
  const SafetyScoreRing({
    required this.label,
    required this.score,
    required this.color,
    this.size = 72,
    super.key,
  });

  final String label;
  final double score;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = (score / 100).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
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
