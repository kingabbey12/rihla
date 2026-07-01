import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/home/presentation/providers/home_dashboard_providers.dart';
import 'package:rihla/features/home/presentation/widgets/home_dashboard_entrance.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/design/rihla_glass.dart';
import 'package:rihla/shared/design/rihla_radii.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

class HomeTodaysDrivingCard extends ConsumerWidget {
  const HomeTodaysDrivingCard({super.key});

  String _formatDuration(int minutes) {
    if (minutes <= 0) return '0m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final drivingAsync = ref.watch(homeTodaysDrivingProvider);

    return HomeDashboardEntrance(
      delayMs: 320,
      child: RihlaGlassSurface(
        borderRadius: RihlaRadii.cardAll,
        padding: const EdgeInsets.all(20),
        onTap: () => context.push(RoutePaths.profile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  color: RihlaReferenceTokens.mapTeal,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.homeTodaysDriving,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            drivingAsync.when(
              loading: () => const Row(
                children: [
                  Expanded(child: HomeSkeletonBox(height: 52)),
                  SizedBox(width: 10),
                  Expanded(child: HomeSkeletonBox(height: 52)),
                ],
              ),
              error: (_, _) => _StatGrid(
                trips: 0,
                distanceKm: 0,
                drivingScore: 0,
                drivingMinutes: 0,
                formatDuration: _formatDuration,
              ),
              data: (stats) => _StatGrid(
                trips: stats.trips,
                distanceKm: stats.distanceKm,
                drivingScore: stats.drivingScore,
                drivingMinutes: stats.drivingMinutes,
                formatDuration: _formatDuration,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.trips,
    required this.distanceKm,
    required this.drivingScore,
    required this.drivingMinutes,
    required this.formatDuration,
  });

  final int trips;
  final double distanceKm;
  final int drivingScore;
  final int drivingMinutes;
  final String Function(int minutes) formatDuration;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: l10n.homeTodaysTrips,
                value: '$trips',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: l10n.homeDistanceLabel,
                value: '${distanceKm.round()} km',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: l10n.homeDrivingScore,
                value: '$drivingScore',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: l10n.homeTimeDriving,
                value: formatDuration(drivingMinutes),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: RihlaRadii.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
