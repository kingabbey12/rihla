import 'package:flutter/material.dart';
import 'package:rihla/features/navigation/domain/entities/lane_guidance.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Premium lane guidance strip: large lane arrows with the recommended lane
/// highlighted. Fades/scales in when lanes appear and out when they clear.
class LaneGuidancePlaceholder extends StatelessWidget {
  const LaneGuidancePlaceholder({
    required this.guidance,
    super.key,
  });

  final LaneGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teal = RihlaReferenceTokens.mapTeal;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          child: child,
        ),
      ),
      child: guidance.lanes.isEmpty
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(guidance.lanes.length),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final lane in guidance.lanes)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOut,
                        width: lane.isRecommended ? 50 : 42,
                        height: lane.isRecommended ? 50 : 42,
                        decoration: BoxDecoration(
                          gradient: lane.isRecommended
                              ? LinearGradient(
                                  colors: [teal, teal.withValues(alpha: 0.72)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: lane.isRecommended
                              ? null
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: lane.isRecommended
                              ? [
                                  BoxShadow(
                                    color: teal.withValues(alpha: 0.32),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          lane.direction.icon,
                          size: lane.isRecommended ? 28 : 22,
                          color: lane.isRecommended
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
