import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/app/coordinators/driving_session_coordinator.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/shared/design/rihla_design.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Minimal navigation controls shown throughout active turn-by-turn guidance.
class NavigationControlsOverlay extends ConsumerWidget {
  const NavigationControlsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNavigating = ref.watch(navigationIsActiveProvider);
    if (!isNavigating) return const SizedBox.shrink();

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
          right: 16,
          bottom: 20 + bottomInset,
          child: _EndTripPill(
            label: l10n.navControlEnd,
            onTap: () => _endTrip(context, ref),
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

}

class _EndTripPill extends StatelessWidget {
  const _EndTripPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final red = RihlaReferenceTokens.emergencyRed;
    final glass = theme.colorScheme.surface.withValues(
      alpha: isDark ? 0.82 : 0.92,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: RihlaGlass.blurSigma,
          sigmaY: RihlaGlass.blurSigma,
        ),
        child: Container(
          key: const ValueKey('nav_controls_bar'),
          decoration: BoxDecoration(
            color: glass,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: red.withValues(alpha: 0.24)),
            boxShadow: RihlaReferenceTokens.floatingShadow(opacity: 0.2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('nav_end_trip'),
              borderRadius: BorderRadius.circular(999),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, color: red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
