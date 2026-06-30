import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/navigation/presentation/widgets/speed_limit_badge.dart';

/// Floating speed and speed-limit cluster shown during active navigation.
///
/// The badge stays visible for the entire navigation session. When the live
/// speed limit is unknown it shows a "--" placeholder rather than disappearing.
class NavigationSpeedLimitOverlay extends ConsumerWidget {
  const NavigationSpeedLimitOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(navigationIsActiveProvider);
    final speedKmh = ref.watch(navigationSpeedProvider) ?? 0;
    final speedLimit = ref.watch(navigationSpeedLimitProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: !isActive
          ? const SizedBox.shrink()
          : Align(
              key: const ValueKey('speed-limit'),
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 0, 18 + bottom),
                child: _SpeedCluster(
                  speedKmh: speedKmh,
                  limitKmh: speedLimit?.limitKmh,
                ),
              ),
            ),
    );
  }
}

class _SpeedCluster extends StatelessWidget {
  const _SpeedCluster({required this.speedKmh, required this.limitKmh});

  final double speedKmh;
  final int? limitKmh;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 78,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: _CurrentSpeedBadge(speedKmh: speedKmh),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: SpeedLimitBadge(limitKmh: limitKmh, size: 46),
          ),
        ],
      ),
    );
  }
}

class _CurrentSpeedBadge extends StatelessWidget {
  const _CurrentSpeedBadge({required this.speedKmh});

  final double speedKmh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            speedKmh.round().toString(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Text(
            'km/h',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
