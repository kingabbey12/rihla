import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/navigation/presentation/widgets/speed_limit_badge.dart';

/// Floating speed-limit badge shown bottom-left during active navigation.
class NavigationSpeedLimitOverlay extends ConsumerWidget {
  const NavigationSpeedLimitOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(navigationIsActiveProvider);
    final speedLimit = ref.watch(navigationSpeedLimitProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: (!isActive || speedLimit == null)
          ? const SizedBox.shrink()
          : Align(
              key: const ValueKey('speed-limit'),
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 0, 150 + bottom),
                child: SpeedLimitBadge(limitKmh: speedLimit.limitKmh),
              ),
            ),
    );
  }
}
