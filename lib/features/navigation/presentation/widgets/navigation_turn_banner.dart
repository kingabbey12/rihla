import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_maneuver.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/presentation/extensions/maneuver_type_icons.dart';
import 'package:rihla/features/navigation/presentation/widgets/lane_guidance_placeholder.dart';

/// Turn-by-turn banner showing the next maneuver and trip summary.
class NavigationTurnBanner extends StatelessWidget {
  const NavigationTurnBanner({
    required this.session,
    required this.onToggleVoice,
    super.key,
  });

  final NavigationSession session;
  final VoidCallback onToggleVoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maneuver = session.currentManeuver;
    final top = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, top + 56, 12, 0),
      child: Material(
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ManeuverIcon(maneuver: maneuver),
                  const SizedBox(width: 12),
                  Expanded(child: _ManeuverText(maneuver: maneuver)),
                  IconButton(
                    icon: Icon(
                      session.voiceEnabled
                          ? Icons.volume_up
                          : Icons.volume_off,
                    ),
                    tooltip: session.voiceEnabled
                        ? context.l10n.navVoiceMute
                        : context.l10n.navVoiceUnmute,
                    onPressed: onToggleVoice,
                  ),
                ],
              ),
              if (session.laneGuidance.lanes.isNotEmpty) ...[
                const SizedBox(height: 10),
                LaneGuidancePlaceholder(guidance: session.laneGuidance),
              ],
              const SizedBox(height: 10),
              _TripSummaryRow(session: session),
              if (session.isOffRoute) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.navOffRoute,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ManeuverIcon extends StatelessWidget {
  const _ManeuverIcon({required this.maneuver});

  final NavigationManeuver maneuver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        maneuver.type.icon,
        color: theme.colorScheme.onPrimaryContainer,
        size: 30,
      ),
    );
  }
}

class _ManeuverText extends StatelessWidget {
  const _ManeuverText({required this.maneuver});

  final NavigationManeuver maneuver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceM = (maneuver.distanceToManeuverKm * 1000).round();
    final distanceLabel = distanceM >= 1000
        ? context.l10n.navDistanceKm(maneuver.distanceToManeuverKm.toStringAsFixed(1))
        : context.l10n.navDistanceMeters(distanceM);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          distanceLabel,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          maneuver.instruction,
          style: theme.textTheme.bodyMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${context.l10n.navThen} ${maneuver.nextRoad}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TripSummaryRow extends StatelessWidget {
  const _TripSummaryRow({required this.session});

  final NavigationSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eta = TimeOfDay.fromDateTime(session.eta);
    final etaLabel = MaterialLocalizations.of(context).formatTimeOfDay(eta);

    return Row(
      children: [
        Expanded(
          child: Text(
            session.currentRoad,
            style: theme.textTheme.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          context.l10n.journeyKm(session.remainingDistanceKm.toStringAsFixed(1)),
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(width: 12),
        Text(
          etaLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (session.speedLimit.isPlaceholder) ...[
          const SizedBox(width: 12),
          Text(
            context.l10n.navSpeedLimit(session.speedLimit.limitKmh),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
