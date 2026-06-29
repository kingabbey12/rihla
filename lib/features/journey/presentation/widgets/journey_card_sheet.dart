import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/journey/presentation/extensions/journey_metrics_l10n.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_ai_summary_card.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_journey_advisor_card.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_departure_suggestions.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_metric_tile.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_score_badge.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_route_details_section.dart';
import 'package:rihla/shared/widgets/premium_buttons.dart';

/// Premium journey preview card shown over the map before navigation.
class JourneyCardSheet extends StatelessWidget {
  const JourneyCardSheet({
    required this.summary,
    required this.onStart,
    required this.onCancel,
    super.key,
  });

  final JourneySummary summary;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = summary.metrics;
    final score = summary.score;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _DestinationHeader(destination: summary.destination),
                    const SizedBox(height: 20),
                    const JourneyRouteDetailsSection(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        JourneyScoreBadge(
                          label: context.l10n.journeyScore,
                          score: score.journeyScore,
                          color: theme.colorScheme.primary,
                        ),
                        JourneyScoreBadge(
                          label: context.l10n.journeySafetyScore,
                          score: score.safetyScore,
                          color: theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: JourneyMetricTile(
                            icon: Icons.straighten,
                            label: context.l10n.journeyDistance,
                            value: context.l10n.journeyKm(
                              metrics.distanceKm.toStringAsFixed(1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: JourneyMetricTile(
                            icon: Icons.schedule,
                            label: context.l10n.journeyDuration,
                            value: context.l10n.journeyMinutes(
                              metrics.durationMinutes,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: JourneyMetricTile(
                            icon: Icons.wb_sunny_outlined,
                            label: context.l10n.journeyWeather,
                            value:
                                '${metrics.weatherSummary}\n${context.l10n.journeyTemperature(metrics.temperatureCelsius.toStringAsFixed(0))}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: JourneyMetricTile(
                            icon: Icons.traffic_outlined,
                            label: context.l10n.journeyTraffic,
                            value: context.trafficLabel(metrics.trafficLevel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: JourneyMetricTile(
                            icon: Icons.local_gas_station_outlined,
                            label: context.l10n.journeyFuel,
                            value: context.l10n.journeyLiters(
                              metrics.fuelEstimateLiters.toStringAsFixed(1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: JourneyMetricTile(
                            icon: Icons.battery_charging_full_outlined,
                            label: context.l10n.journeyBattery,
                            value: context.l10n.journeyBatteryPercent(
                              metrics.batteryEstimatePercent
                                  .toStringAsFixed(0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    JourneyMetricTile(
                      icon: Icons.alt_route,
                      label: context.l10n.journeyRoadConditions,
                      value: context.roadConditionLabel(metrics.roadCondition),
                    ),
                    const SizedBox(height: 20),
                    const AiJourneyAdvisorCard(),
                    const SizedBox(height: 20),
                    JourneyDepartureSuggestions(
                      suggestions: metrics.departureSuggestions,
                    ),
                    const SizedBox(height: 20),
                    JourneyAiSummaryCard(summary: summary.aiSummary),
                    const SizedBox(height: 24),
                    PremiumPrimaryButton(
                      label: context.l10n.journeyStart,
                      onPressed: onStart,
                    ),
                    const SizedBox(height: 10),
                    PremiumSecondaryButton(
                      label: context.l10n.journeyCancel,
                      onPressed: onCancel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DestinationHeader extends StatelessWidget {
  const _DestinationHeader({required this.destination});

  final JourneyEndpoint destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.place,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.journeyDestination,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                destination.name,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                destination.address,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
