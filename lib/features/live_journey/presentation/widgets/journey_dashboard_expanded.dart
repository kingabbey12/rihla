import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/extensions/live_metric_formatters.dart';
import 'package:rihla/features/live_journey/presentation/widgets/live_metric_tile.dart';
import 'package:rihla/features/live_journey/presentation/widgets/live_score_metric.dart';

/// Full bottom sheet with all live journey metrics.
class JourneyDashboardExpanded extends StatelessWidget {
  const JourneyDashboardExpanded({
    required this.state,
    required this.onCollapse,
    required this.onFloat,
    super.key,
  });

  final LiveJourneyActive state;
  final VoidCallback onCollapse;
  final VoidCallback onFloat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = state.metrics;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + bottom),
        child: Material(
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: theme.colorScheme.surface,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.62,
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
                          context.l10n.liveJourneyTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.picture_in_picture_alt, size: 20),
                        tooltip: context.l10n.liveJourneyFloat,
                        onPressed: onFloat,
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        tooltip: context.l10n.liveJourneyCollapse,
                        onPressed: onCollapse,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    shrinkWrap: true,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: state.progressPercent / 100,
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          LiveScoreMetric(
                            label: context.l10n.journeyScore,
                            metric: metrics.journeyScore,
                            color: theme.colorScheme.primary,
                          ),
                          LiveScoreMetric(
                            label: context.l10n.journeySafetyScore,
                            metric: metrics.safetyScore,
                            color: theme.colorScheme.secondary,
                          ),
                          LiveScoreMetric(
                            label: context.l10n.liveJourneyTrafficScore,
                            metric: metrics.trafficScore,
                            color: theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LiveMetricTile(
                        icon: Icons.turn_right,
                        label: context.l10n.liveJourneyNextManeuver,
                        value: metrics.nextManeuver.value,
                        metric: metrics.nextManeuver,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: LiveMetricTile(
                              icon: Icons.schedule,
                              label: context.l10n.liveJourneyEta,
                              value: context.formatEta(metrics.eta.value),
                              metric: metrics.eta,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LiveMetricTile(
                              icon: Icons.flag,
                              label: context.l10n.liveJourneyArrivalTime,
                              value: context.formatArrivalTime(
                                metrics.arrivalTime.value,
                              ),
                              metric: metrics.arrivalTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: LiveMetricTile(
                              icon: Icons.straighten,
                              label: context.l10n.liveJourneyRemainingDistance,
                              value: context.formatDistanceKm(
                                metrics.remainingDistanceKm.value,
                              ),
                              metric: metrics.remainingDistanceKm,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LiveMetricTile(
                              icon: Icons.speed,
                              label: context.l10n.liveJourneyCurrentSpeed,
                              value: context.formatSpeedKmh(
                                metrics.currentSpeedKmh.value,
                              ),
                              metric: metrics.currentSpeedKmh,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: LiveMetricTile(
                              icon: Icons.wb_sunny_outlined,
                              label: context.l10n.journeyWeather,
                              value: metrics.weather.value,
                              metric: metrics.weather,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LiveMetricTile(
                              icon: Icons.construction_outlined,
                              label: context.l10n.journeyRoadConditions,
                              value: metrics.roadCondition.value,
                              metric: metrics.roadCondition,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: LiveMetricTile(
                              icon: Icons.local_gas_station_outlined,
                              label: context.l10n.journeyFuel,
                              value: context.formatFuelLiters(
                                metrics.fuelEstimateLiters.value,
                              ),
                              metric: metrics.fuelEstimateLiters,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LiveMetricTile(
                              icon: Icons.battery_charging_full,
                              label: context.l10n.journeyBattery,
                              value: context.formatBatteryPercent(
                                metrics.batteryEstimatePercent.value,
                              ),
                              metric: metrics.batteryEstimatePercent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LiveMetricTile(
                        icon: Icons.route,
                        label: context.l10n.liveJourneyCurrentRoad,
                        value: metrics.currentRoadName.value,
                        metric: metrics.currentRoadName,
                      ),
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
