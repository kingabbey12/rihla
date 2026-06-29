import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/extensions/live_metric_formatters.dart';
import 'package:rihla/features/live_journey/presentation/widgets/journey_dashboard_header.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Premium Driver HUD: animated speed readout, progress, and trip metrics.
class JourneyDashboardCollapsed extends StatelessWidget {
  const JourneyDashboardCollapsed({
    required this.state,
    required this.onExpand,
    required this.onFloat,
    super.key,
  });

  final LiveJourneyActive state;
  final VoidCallback onExpand;
  final VoidCallback onFloat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = state.metrics;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final teal = RihlaReferenceTokens.mapTeal;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            elevation: 10,
            shadowColor: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(22),
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  JourneyDashboardHeader(
                    state: state,
                    onExpand: onExpand,
                    onFloat: onFloat,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        _SpeedReadout(speedKmh: metrics.currentSpeedKmh.value),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _ProgressBar(percent: state.progressPercent),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _HudMetric(
                                      icon: Icons.straighten_rounded,
                                      value: context.formatDistanceKm(
                                        metrics.remainingDistanceKm.value,
                                      ),
                                      label: context.l10n.navDistanceLeft,
                                    ),
                                  ),
                                  Expanded(
                                    child: _HudMetric(
                                      icon: Icons.schedule_rounded,
                                      value: context.formatArrivalTime(
                                        metrics.arrivalTime.value,
                                      ),
                                      label: context.l10n.navEtaLabel,
                                    ),
                                  ),
                                  Expanded(
                                    child: _HudMetric(
                                      icon: Icons.local_gas_station_rounded,
                                      value: context.formatFuelLiters(
                                        metrics.fuelEstimateLiters.value,
                                      ),
                                      label: context.l10n.journeyFuel,
                                      color: teal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedReadout extends StatelessWidget {
  const _SpeedReadout({required this.speedKmh});

  final double speedKmh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teal = RihlaReferenceTokens.mapTeal;
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [teal.withValues(alpha: 0.14), teal.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: teal.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: speedKmh),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, _) => Text(
              value.round().toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: teal,
                height: 1,
              ),
            ),
          ),
          Text(
            'km/h',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (percent / 100).clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 8,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          color: RihlaReferenceTokens.mapTeal,
        ),
      ),
    );
  }
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: color ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Text(
                  value,
                  key: ValueKey(value),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
