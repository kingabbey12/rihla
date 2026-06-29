import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/safety/presentation/providers/safety_providers.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';
import 'package:rihla/shared/ui/rihla_score_gauge.dart';
import 'package:rihla/shared/widgets/empty_screen.dart';

/// Route details driven by live route selection and safety assessment data.
class JourneyRouteDetailsSection extends ConsumerStatefulWidget {
  const JourneyRouteDetailsSection({super.key});

  @override
  ConsumerState<JourneyRouteDetailsSection> createState() =>
      _JourneyRouteDetailsSectionState();
}

class _JourneyRouteDetailsSectionState
    extends ConsumerState<JourneyRouteDetailsSection> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assessment = ref.watch(safetyAssessmentProvider);
    final routeState = ref.watch(routeControllerProvider);
    final journeySummary = ref.watch(journeyControllerProvider.notifier).activeSummary;

    const tabs = [
      _RouteMode('Safe', Icons.shield_outlined, RihlaReferenceTokens.mapTeal),
      _RouteMode('Fast', Icons.speed_outlined, Color(0xFF2563EB)),
      _RouteMode('Eco', Icons.eco_outlined, Color(0xFF159947)),
      _RouteMode('Scenic', Icons.landscape_outlined, Color(0xFFB45309)),
    ];

    final safetyScore = assessment?.overallSafetyScore.round() ??
        journeySummary?.score.safetyScore.round() ??
        0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final tab = tabs[index];
              final selected = _tab == index;
              return _RouteModeCard(
                mode: tab,
                selected: selected,
                onTap: () => setState(() => _tab = index),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tabs[_tab].color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(tabs[_tab].icon, color: tabs[_tab].color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _explanationFor(_tab),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (safetyScore > 0) ...[
          Center(
            child: RihlaScoreGauge(
              score: safetyScore,
              label: 'Safety Score',
              subtitle: 'Live',
              size: 120,
            ),
          ),
          const SizedBox(height: 16),
          if (assessment != null) ...[
            _SafetyRow(label: 'Road safety', score: assessment.roadSafety, theme: theme),
            _SafetyRow(label: 'Traffic risk', score: 100 - assessment.trafficRisk, theme: theme),
            _SafetyRow(label: 'Weather risk', score: 100 - assessment.weatherRisk, theme: theme),
            _SafetyRow(label: 'Vehicle readiness', score: assessment.vehicleReadiness, theme: theme),
          ],
        ] else
          const EmptyScreen(
            title: 'Safety data loading',
            message: 'Scores appear once your route and live conditions are available.',
            icon: Icons.shield_outlined,
          ),
        const SizedBox(height: 16),
        Text(
          'Route',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        switch (routeState) {
          RouteReady(:final result) => Column(
              children: [
                for (final route in result.routes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          RihlaReferenceTokens.mapTeal.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.route,
                        color: RihlaReferenceTokens.mapTeal,
                        size: 20,
                      ),
                    ),
                    title: Text(route.profile.name),
                    subtitle: Text(
                      '${route.distanceKm.toStringAsFixed(1)} km · '
                      '${(route.durationSeconds / 60).round()} min',
                    ),
                  ),
              ],
            ),
          RouteSelected(:final selected) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(selected.profile.name),
              subtitle: Text(
                '${selected.distanceKm.toStringAsFixed(1)} km · '
                '${(selected.durationSeconds / 60).round()} min',
              ),
            ),
          _ => const EmptyScreen(
              title: 'No route yet',
              message: 'Start a journey to calculate live route options.',
              icon: Icons.route_outlined,
            ),
        },
      ],
    );
  }

  String _explanationFor(int tab) => switch (tab) {
        0 => 'Avoids complex junctions and prioritises well-lit main roads.',
        1 => 'Uses the fastest corridor while keeping traffic risk visible.',
        2 => 'Optimised for smoother acceleration and lower fuel use.',
        _ => 'Adds a calmer drive with cleaner roads and nearby stops.',
      };
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({
    required this.label,
    required this.score,
    required this.theme,
  });

  final String label;
  final double score;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: theme.textTheme.bodyMedium)),
          Expanded(
            flex: 2,
            child: Text(
              '${score.round()}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: RihlaReferenceTokens.mapTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMode {
  const _RouteMode(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class _RouteModeCard extends StatelessWidget {
  const _RouteModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final _RouteMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScale(
      scale: selected ? 1.02 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Material(
        color: selected
            ? mode.color.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            width: 96,
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? mode.color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(mode.icon, color: mode.color, size: 22),
                const SizedBox(height: 6),
                Text(
                  mode.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
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
