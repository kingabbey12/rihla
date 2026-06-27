import 'package:flutter/material.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/extensions/live_metric_formatters.dart';
import 'package:rihla/features/live_journey/presentation/widgets/journey_dashboard_header.dart';

/// Minimal bottom bar with ETA, speed, and road name.
class JourneyDashboardCollapsed extends StatelessWidget {
  const JourneyDashboardCollapsed({
    required this.state,
    required this.onExpand,
    required this.onFloat,
    super.key,
  });

  final LiveJourneyActive state;
  final VoidCallback onExpand;
  final VoidCallback onFloat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = state.metrics;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
        child: Material(
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                JourneyDashboardHeader(
                  state: state,
                  onExpand: onExpand,
                  onFloat: onFloat,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.progressPercent / 100,
                    minHeight: 4,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.speed,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.formatSpeedKmh(metrics.currentSpeedKmh.value),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      context.formatDistanceKm(
                        metrics.remainingDistanceKm.value,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
