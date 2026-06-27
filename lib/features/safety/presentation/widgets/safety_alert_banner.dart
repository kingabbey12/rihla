import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/safety/domain/entities/hazard.dart';
import 'package:rihla/features/safety/presentation/extensions/hazard_l10n.dart';

/// Banner for the highest-priority safety alert.
class SafetyAlertBanner extends StatelessWidget {
  const SafetyAlertBanner({
    required this.hazard,
    super.key,
  });

  final Hazard hazard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hazard.severity.color(theme.colorScheme);

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: color.withValues(alpha: 0.12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(hazard.type.icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.safetyAlertTitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    hazard.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    hazard.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hazard.distanceAheadKm > 0)
              Text(
                context.l10n.safetyHazardDistance(
                  hazard.distanceAheadKm.toStringAsFixed(1),
                ),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
