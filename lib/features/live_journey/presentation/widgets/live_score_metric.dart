import 'package:flutter/material.dart';
import 'package:rihla/features/live_journey/domain/entities/journey_metric.dart';
import 'package:rihla/features/live_journey/presentation/extensions/live_metric_formatters.dart';
import 'package:rihla/features/live_journey/presentation/widgets/live_metric_status_indicator.dart';

/// Circular score widget with live status indicator.
class LiveScoreMetric extends StatelessWidget {
  const LiveScoreMetric({
    required this.label,
    required this.metric,
    required this.color,
    super.key,
  });

  final String label;
  final JourneyMetric<double> metric;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = (metric.value / 100).clamp(0.0, 1.0);

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
                context.formatScore(metric.value),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: LiveMetricStatusIndicator(status: metric.status),
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
