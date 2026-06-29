import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/app/coordinators/driving_session_coordinator.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/design/rihla_design.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Persistent navigation controls shown throughout active turn-by-turn guidance.
///
/// End Trip, Mute, Report, and Overview remain visible at all times so the user
/// always has a clear way to end or manage the session.
class NavigationControlsOverlay extends ConsumerWidget {
  const NavigationControlsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNavigating = ref.watch(navigationIsActiveProvider);
    if (!isNavigating) return const SizedBox.shrink();

    final voiceEnabled = ref.watch(navigationVoiceEnabledProvider) ?? true;
    final l10n = context.l10n;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        // Double-tap anywhere on the map to resume follow mode.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: () {
              RihlaHaptics.selection();
              ref.read(navigationFollowRecenterProvider.notifier).request();
            },
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          // Float above the Driver HUD card which owns the bottom-centre.
          bottom: 172 + bottomInset,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _ControlBar(
                voiceEnabled: voiceEnabled,
                onEnd: () => _endTrip(context, ref),
                onMute: () => _toggleMute(ref),
                onReport: () => context.push(RoutePaths.reportIncident),
                onOverview: () => ref
                    .read(navigationOverviewRequestProvider.notifier)
                    .request(),
                onRecenter: () => ref
                    .read(navigationFollowRecenterProvider.notifier)
                    .request(),
                l10n: l10n,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _endTrip(BuildContext context, WidgetRef ref) async {
    RihlaHaptics.warning();
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.navEndConfirmTitle),
        content: Text(l10n.navEndConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.navKeepDriving),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: RihlaReferenceTokens.emergencyRed,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.navEndConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      RihlaHaptics.confirmation();
      await ref.read(drivingSessionCoordinatorProvider).cancelDrivingSession();
    }
  }

  void _toggleMute(WidgetRef ref) {
    final enabled = ref.read(navigationVoiceEnabledProvider) ?? true;
    RihlaHaptics.selection();
    ref
        .read(navigationSessionControllerProvider.notifier)
        .setVoiceEnabled(!enabled);
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.voiceEnabled,
    required this.onEnd,
    required this.onMute,
    required this.onReport,
    required this.onOverview,
    required this.onRecenter,
    required this.l10n,
  });

  final bool voiceEnabled;
  final VoidCallback onEnd;
  final VoidCallback onMute;
  final VoidCallback onReport;
  final VoidCallback onOverview;
  final VoidCallback onRecenter;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glass = theme.colorScheme.surface.withValues(alpha: isDark ? 0.78 : 0.86);

    return ClipRRect(
      borderRadius: BorderRadius.circular(RihlaReferenceTokens.navBarRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: RihlaGlass.blurSigma,
          sigmaY: RihlaGlass.blurSigma,
        ),
        child: Container(
          key: const ValueKey('nav_controls_bar'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: glass,
            borderRadius:
                BorderRadius.circular(RihlaReferenceTokens.navBarRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.5),
            ),
            boxShadow: RihlaReferenceTokens.floatingShadow(opacity: 0.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ControlButton(
                key: const ValueKey('nav_end_trip'),
                icon: Icons.close_rounded,
                label: l10n.navControlEnd,
                color: RihlaReferenceTokens.emergencyRed,
                onTap: onEnd,
              ),
              _ControlButton(
                icon: voiceEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label:
                    voiceEnabled ? l10n.navControlMute : l10n.navControlUnmute,
                onTap: onMute,
              ),
              _ControlButton(
                icon: Icons.report_outlined,
                label: l10n.navControlReport,
                color: RihlaReferenceTokens.goldAccent,
                onTap: onReport,
              ),
              _ControlButton(
                icon: Icons.alt_route_rounded,
                label: l10n.navControlOverview,
                onTap: onOverview,
              ),
              _ControlButton(
                icon: Icons.my_location_rounded,
                label: l10n.navControlRecenter,
                onTap: onRecenter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: tint, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
