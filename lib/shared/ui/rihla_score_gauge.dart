import 'package:flutter/material.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Large circular score gauge matching the reference (Safety / Driving Score).
class RihlaScoreGauge extends StatelessWidget {
  const RihlaScoreGauge({
    required this.score,
    required this.label,
    super.key,
    this.subtitle,
    this.size = 140,
    this.color = RihlaReferenceTokens.mapTeal,
  });

  final int score;
  final String label;
  final String? subtitle;
  final double size;
  final Color color;

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
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: normalized,
                  strokeWidth: 10,
                  backgroundColor: color.withValues(alpha: 0.12),
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
