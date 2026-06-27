import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/presentation/extensions/route_profile_l10n.dart';

/// A selectable route alternative card.
class RouteOptionCard extends StatelessWidget {
  const RouteOptionCard({
    required this.route,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final RouteSummary route;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    context.iconForRouteProfile(route.profile),
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.labelForRouteProfile(route.profile),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ],
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: context.l10n.routeDistance,
                value: context.l10n.journeyKm(
                  route.distanceKm.toStringAsFixed(1),
                ),
              ),
              _MetricRow(
                label: context.l10n.routeDuration,
                value: context.l10n.journeyMinutes(route.durationMinutes),
              ),
              _MetricRow(
                label: context.l10n.routeJourneyScore,
                value: '${route.journeyScore.round()}/100',
              ),
              _MetricRow(
                label: context.l10n.routeFuel,
                value: context.l10n.journeyLiters(
                  route.fuelEstimateLiters.toStringAsFixed(1),
                ),
              ),
              _MetricRow(
                label: context.l10n.routeTraffic,
                value: route.trafficSummary,
              ),
              _MetricRow(
                label: context.l10n.routeSafety,
                value: route.safetySummary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
