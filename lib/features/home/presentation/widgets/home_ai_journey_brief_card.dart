import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/home/presentation/models/home_journey_brief.dart';
import 'package:rihla/features/home/presentation/providers/home_dashboard_providers.dart';
import 'package:rihla/features/home/presentation/widgets/home_dashboard_entrance.dart';
import 'package:rihla/shared/design/rihla_glass.dart';
import 'package:rihla/shared/design/rihla_radii.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

class HomeAiJourneyBriefCard extends ConsumerWidget {
  const HomeAiJourneyBriefCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final briefAsync = ref.watch(homeJourneyBriefProvider);

    return HomeDashboardEntrance(
      delayMs: 200,
      child: RihlaGlassSurface(
        borderRadius: RihlaRadii.cardAll,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        RihlaReferenceTokens.mapTeal,
                        RihlaReferenceTokens.mapTeal.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: RihlaRadii.mdAll,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.homeAiJourneyBriefTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            briefAsync.when(
              loading: () => const _BriefSkeleton(),
              error: (_, _) => _UnavailableMessage(message: l10n.homeJourneyBriefUnavailable),
              data: (brief) => brief.available
                  ? _BriefContent(brief: brief)
                  : _UnavailableMessage(message: l10n.homeJourneyBriefUnavailable),
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefSkeleton extends StatelessWidget {
  const _BriefSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        HomeSkeletonBox(height: 14, width: double.infinity),
        SizedBox(height: 10),
        HomeSkeletonBox(height: 14, width: 260),
        SizedBox(height: 10),
        HomeSkeletonBox(height: 14, width: 220),
      ],
    );
  }
}

class _UnavailableMessage extends StatelessWidget {
  const _UnavailableMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.45,
      ),
    );
  }
}

class _BriefContent extends StatelessWidget {
  const _BriefContent({required this.brief});

  final HomeJourneyBrief brief;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        if (brief.trafficSummary != null)
          _BriefRow(
            icon: Icons.traffic_rounded,
            label: l10n.homeTrafficSummary,
            value: brief.trafficSummary!,
          ),
        if (brief.weatherWarning != null)
          _BriefRow(
            icon: Icons.cloud_rounded,
            label: l10n.homeWeatherWarning,
            value: brief.weatherWarning!,
          ),
        if (brief.bestDeparture != null)
          _BriefRow(
            icon: Icons.schedule_rounded,
            label: l10n.homeBestDeparture,
            value: brief.bestDeparture!,
          ),
        if (brief.roadIncidents != null)
          _BriefRow(
            icon: Icons.warning_amber_rounded,
            label: l10n.homeRoadIncidents,
            value: brief.roadIncidents!,
          ),
        if (brief.aiRecommendation != null)
          _BriefRow(
            icon: Icons.tips_and_updates_rounded,
            label: l10n.homeAiRecommendation,
            value: brief.aiRecommendation!,
          ),
      ],
    );
  }
}

class _BriefRow extends StatelessWidget {
  const _BriefRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: RihlaReferenceTokens.mapTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
