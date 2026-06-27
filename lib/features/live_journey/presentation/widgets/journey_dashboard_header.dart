import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/extensions/live_metric_formatters.dart';

/// Compact header strip for live journey dashboard modes.
class JourneyDashboardHeader extends StatelessWidget {
  const JourneyDashboardHeader({
    required this.state,
    required this.onExpand,
    this.onFloat,
    super.key,
  });

  final LiveJourneyActive state;
  final VoidCallback onExpand;
  final VoidCallback? onFloat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = state.metrics;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.liveJourneyInProgress,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metrics.currentRoadName.value,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          context.formatEta(metrics.eta.value),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.open_in_full, size: 20),
          tooltip: context.l10n.liveJourneyExpand,
          onPressed: onExpand,
        ),
        if (onFloat != null)
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt, size: 20),
            tooltip: context.l10n.liveJourneyFloat,
            onPressed: onFloat,
          ),
      ],
    );
  }
}
