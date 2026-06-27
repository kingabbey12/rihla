import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/extensions/live_metric_formatters.dart';
import 'package:rihla/features/live_journey/presentation/widgets/live_score_metric.dart';

/// Compact floating card pinned to the top-right of the map.
class JourneyDashboardFloating extends StatelessWidget {
  const JourneyDashboardFloating({
    required this.state,
    required this.onCollapse,
    required this.onExpand,
    super.key,
  });

  final LiveJourneyActive state;
  final VoidCallback onCollapse;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = state.metrics;
    final top = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: top + 120,
      right: 12,
      child: Material(
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.liveJourneyTitle,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.unfold_more, size: 20),
                      tooltip: context.l10n.liveJourneyExpand,
                      onPressed: onExpand,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close_fullscreen, size: 20),
                      tooltip: context.l10n.liveJourneyCollapse,
                      onPressed: onCollapse,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LiveScoreMetric(
                  label: context.l10n.journeyScore,
                  metric: metrics.journeyScore,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  metrics.currentRoadName.value,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  context.formatEta(metrics.eta.value),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.formatSpeedKmh(metrics.currentSpeedKmh.value),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
