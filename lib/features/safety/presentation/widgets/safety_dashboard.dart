import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/safety/domain/entities/hazard.dart';
import 'package:rihla/features/safety/domain/entities/safety_assessment.dart';
import 'package:rihla/features/safety/presentation/extensions/hazard_l10n.dart';
import 'package:rihla/features/safety/presentation/widgets/safety_metric_tile.dart';
import 'package:rihla/features/safety/presentation/widgets/safety_score_ring.dart';

/// Compact journey risk summary card.
class JourneyRiskCard extends StatelessWidget {
  const JourneyRiskCard({
    required this.assessment,
    required this.onOpenDashboard,
    super.key,
  });

  final SafetyAssessment assessment;
  final VoidCallback onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final risk = assessment.journeyRisk;
    final color = risk >= 60
        ? theme.colorScheme.error
        : risk >= 35
            ? theme.colorScheme.tertiary
            : theme.colorScheme.primary;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onOpenDashboard,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.safetyJourneyRisk,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      context.l10n.safetyRiskLevel(risk.round()),
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              Text(
                '${assessment.overallSafetyScore.round()}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scrollable list of active hazards.
class HazardFeed extends StatelessWidget {
  const HazardFeed({
    required this.hazards,
    super.key,
  });

  final List<Hazard> hazards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (hazards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          context.l10n.safetyNoHazards,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: hazards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final hazard = hazards[index];
        final color = hazard.severity.color(theme.colorScheme);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(hazard.type.icon, color: color, size: 20),
          ),
          title: Text(hazard.title),
          subtitle: Text(hazard.description, maxLines: 2),
          trailing: hazard.distanceAheadKm > 0
              ? Text(
                  context.l10n.safetyHazardDistance(
                    hazard.distanceAheadKm.toStringAsFixed(1),
                  ),
                  style: theme.textTheme.labelSmall,
                )
              : null,
        );
      },
    );
  }
}

/// Full safety dashboard with scores and hazard feed.
class SafetyDashboard extends StatelessWidget {
  const SafetyDashboard({
    required this.assessment,
    required this.hazards,
    required this.onClose,
    super.key,
  });

  final SafetyAssessment assessment;
  final List<Hazard> hazards;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + bottom),
        child: Material(
          elevation: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: theme.colorScheme.surface,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.safetyDashboardTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SafetyScoreRing(
                            label: context.l10n.safetyOverallScore,
                            score: assessment.overallSafetyScore,
                            color: theme.colorScheme.primary,
                          ),
                          SafetyScoreRing(
                            label: context.l10n.safetyRoadSafety,
                            score: assessment.roadSafety,
                            color: theme.colorScheme.secondary,
                          ),
                          SafetyScoreRing(
                            label: context.l10n.safetyJourneyRisk,
                            score: 100 - assessment.journeyRisk,
                            color: theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SafetyMetricTile(
                              icon: Icons.traffic,
                              label: context.l10n.safetyTrafficRisk,
                              value: '${assessment.trafficRisk.round()}%',
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SafetyMetricTile(
                              icon: Icons.cloud_outlined,
                              label: context.l10n.safetyWeatherRisk,
                              value: '${assessment.weatherRisk.round()}%',
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SafetyMetricTile(
                              icon: Icons.visibility_outlined,
                              label: context.l10n.safetyDriverAlertness,
                              value: '${assessment.driverAlertness.round()}',
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SafetyMetricTile(
                              icon: Icons.directions_car_outlined,
                              label: context.l10n.safetyVehicleReadiness,
                              value: '${assessment.vehicleReadiness.round()}',
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.l10n.safetyHazardFeedTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      HazardFeed(hazards: hazards),
                    ],
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
