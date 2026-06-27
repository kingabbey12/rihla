import 'package:flutter/material.dart';
import 'package:rihla/features/navigation/domain/entities/lane_guidance.dart';

/// Placeholder lane guidance strip until live lane data is available.
class LaneGuidancePlaceholder extends StatelessWidget {
  const LaneGuidancePlaceholder({
    required this.guidance,
    super.key,
  });

  final LaneGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final lane in guidance.lanes)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: lane.isRecommended
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: lane.isRecommended
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
              child: Icon(
                lane.direction.icon,
                size: 20,
                color: lane.isRecommended
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (guidance.isPlaceholder)
          Text(
            'Lane guidance preview',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

extension on LaneDirection {
  IconData get icon => switch (this) {
        LaneDirection.straight => Icons.straight,
        LaneDirection.slightLeft => Icons.turn_slight_left,
        LaneDirection.slightRight => Icons.turn_slight_right,
        LaneDirection.left => Icons.turn_left,
        LaneDirection.right => Icons.turn_right,
        LaneDirection.uTurn => Icons.u_turn_left,
      };
}
