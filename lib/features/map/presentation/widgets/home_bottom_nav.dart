import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_selectors.dart';
import 'package:rihla/routes/route_paths.dart';

/// Primary bottom navigation for the home experience. The selected tab is
/// derived from the existing explore/emergency activation providers so the bar
/// stays in sync with whatever surface is showing on the map. Hidden during
/// active turn-by-turn navigation.
class HomeBottomNav extends ConsumerWidget {
  const HomeBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNavigating = ref.watch(navigationIsActiveProvider);
    if (isNavigating) return const SizedBox.shrink();

    final exploreActive = ref.watch(exploreActiveProvider);
    final emergencyActive = ref.watch(emergencyActiveProvider);
    final selected = emergencyActive ? 2 : (exploreActive ? 1 : 0);

    final scheme = context.colorScheme;
    final l10n = context.l10n;

    void onTap(int index) {
      switch (index) {
        case 0:
          ref.read(exploreControllerProvider.notifier).deactivate();
          ref.read(emergencyControllerProvider.notifier).deactivate();
        case 1:
          ref.read(emergencyControllerProvider.notifier).deactivate();
          ref.read(exploreControllerProvider.notifier).activate();
        case 2:
          ref.read(exploreControllerProvider.notifier).deactivate();
          ref.read(emergencyControllerProvider.notifier).activate();
        case 3:
          context.push(RoutePaths.settings);
      }
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: scheme.surface,
              indicatorColor: scheme.primaryContainer,
              labelTextStyle: WidgetStateProperty.all(
                context.textTheme.labelMedium,
              ),
            ),
            child: NavigationBar(
              selectedIndex: selected,
              height: 68,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              onDestinationSelected: onTap,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.map_outlined),
                  selectedIcon: const Icon(Icons.map_rounded),
                  label: l10n.homeTitle,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: const Icon(Icons.explore_rounded),
                  label: l10n.featureExplore,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.emergency_outlined),
                  selectedIcon: const Icon(Icons.emergency_rounded),
                  label: l10n.featureEmergency,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: l10n.featureProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
