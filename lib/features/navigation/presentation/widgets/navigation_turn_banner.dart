import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_maneuver.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/presentation/widgets/lane_guidance_placeholder.dart';
import 'package:rihla/features/navigation/presentation/widgets/maneuver_arrow.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Premium turn-by-turn banner: glass surface, large animated maneuver arrow,
/// distance countdown, next road, lane guidance, and a trip metrics row.
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
    final isDark = theme.brightness == Brightness.dark;
    final maneuver = session.currentManeuver;
    final top = MediaQuery.paddingOf(context).top;

    // Approach progress: ring fills within the last 800 m before the turn.
    final progress =
        (1 - (maneuver.distanceToManeuverKm / 0.8)).clamp(0.0, 1.0);

    final glass = theme.colorScheme.surface.withValues(
      alpha: isDark ? 0.78 : 0.86,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(12, top + 12, 12, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          key: const ValueKey('nav_turn_banner_card'),
          constraints: const BoxConstraints(maxWidth: 640),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: RihlaReferenceTokens.floatingShadow(opacity: 0.22),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: glass,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.08 : 0.5,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ManeuverArrow(
                            type: maneuver.type,
                            progress: progress,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ManeuverText(
                              maneuver: maneuver,
                              currentRoad: session.currentRoad,
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: Icon(
                              session.voiceEnabled
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                            ),
                            tooltip: session.voiceEnabled
                                ? context.l10n.navVoiceMute
                                : context.l10n.navVoiceUnmute,
                            onPressed: onToggleVoice,
                          ),
                        ],
                      ),
                      if (session.laneGuidance.lanes.length >= 2) ...[
                        const SizedBox(height: 14),
                        LaneGuidancePlaceholder(
                          guidance: session.laneGuidance,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _TripMetricsRow(session: session),
                      _OffRouteNotice(isOffRoute: session.isOffRoute),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManeuverText extends StatelessWidget {
  const _ManeuverText({required this.maneuver, required this.currentRoad});

  final NavigationManeuver maneuver;
  final String currentRoad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceM = (maneuver.distanceToManeuverKm * 1000).round();
    final distanceLabel = distanceM >= 1000
        ? context.l10n
            .navDistanceKm(maneuver.distanceToManeuverKm.toStringAsFixed(1))
        : context.l10n.navDistanceMeters(distanceM);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.my_location_rounded,
              size: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                currentRoad,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            distanceLabel,
            key: ValueKey(distanceLabel),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          maneuver.instruction,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${context.l10n.navThen} ${maneuver.nextRoad}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TripMetricsRow extends StatelessWidget {
  const _TripMetricsRow({required this.session});

  final NavigationSession session;

  @override
  Widget build(BuildContext context) {
    final eta = TimeOfDay.fromDateTime(session.eta);
    final etaLabel = MaterialLocalizations.of(context).formatTimeOfDay(eta);
    final minutes = session.remainingDuration.inMinutes;
    final timeLeft = minutes >= 60
        ? '${minutes ~/ 60} h ${minutes % 60} min'
        : context.l10n.journeyMinutes(minutes);

    return Row(
      children: [
        Expanded(
          child: _Metric(
            label: context.l10n.navEtaLabel,
            value: etaLabel,
          ),
        ),
        _Divider(),
        Expanded(
          child: _Metric(
            label: context.l10n.navTimeLeft,
            value: timeLeft,
          ),
        ),
        _Divider(),
        Expanded(
          child: _Metric(
            label: context.l10n.navDistanceLeft,
            value: context.l10n
                .journeyKm(session.remainingDistanceKm.toStringAsFixed(1)),
          ),
        ),
        if (session.speedLimit.isPlaceholder) ...[
          const SizedBox(width: 12),
          // Compact inline limit chip; full badge lives in the HUD.
          _LimitChip(limit: session.speedLimit.limitKmh),
        ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Text(
            value,
            key: ValueKey(value),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
    );
  }
}

class _LimitChip extends StatelessWidget {
  const _LimitChip({required this.limit});

  final int limit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD32F2F), width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        '$limit',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _OffRouteNotice extends StatelessWidget {
  const _OffRouteNotice({required this.isOffRoute});

  final bool isOffRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      child: !isOffRoute
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.navOffRoute,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
