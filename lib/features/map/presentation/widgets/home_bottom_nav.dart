import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_selectors.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';
import 'package:rihla/theme/app_colors.dart';

/// Primary bottom navigation matching the production reference.
class HomeBottomNav extends ConsumerWidget {
  const HomeBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNavigating = ref.watch(navigationIsActiveProvider);
    final routePreviewActive = ref.watch(routePreviewActiveProvider);
    if (isNavigating || routePreviewActive) return const SizedBox.shrink();

    final exploreActive = ref.watch(exploreActiveProvider);
    final emergencyActive = ref.watch(emergencyActiveProvider);
    final selected = emergencyActive ? 2 : (exploreActive ? 1 : 0);

    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void onTap(int index) {
      HapticFeedback.selectionClick();
      switch (index) {
        case 0:
          ref.read(exploreControllerProvider.notifier).deactivate();
          ref.read(emergencyControllerProvider.notifier).deactivate();
        case 1:
          ref.read(emergencyControllerProvider.notifier).deactivate();
          context.push(RoutePaths.exploreNearby);
        case 2:
          ref.read(exploreControllerProvider.notifier).deactivate();
          context.push(RoutePaths.emergencyDashboard);
        case 3:
          context.push(RoutePaths.profile);
      }
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        key: const ValueKey('home_bottom_nav_visible'),
        constraints: const BoxConstraints(maxWidth: 560),
        margin: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          8 + MediaQuery.paddingOf(context).bottom * 0.5,
        ),
        decoration: BoxDecoration(
          color:
              isDark ? RihlaReferenceTokens.darkSurface : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(RihlaReferenceTokens.navBarRadius),
          boxShadow: RihlaReferenceTokens.floatingShadow(opacity: 0.16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RihlaReferenceTokens.navBarRadius),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return context.textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? RihlaReferenceTokens.mapTeal
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: selected,
              height: 64,
              backgroundColor: Colors.transparent,
              animationDuration: const Duration(milliseconds: 500),
              indicatorColor:
                  RihlaReferenceTokens.mapTeal.withValues(alpha: 0.16),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: onTap,
              destinations: [
                _animatedDestination(
                  outlined: Icons.home_outlined,
                  filled: Icons.home_rounded,
                  label: l10n.homeTitle,
                  active: selected == 0,
                ),
                _animatedDestination(
                  outlined: Icons.explore_outlined,
                  filled: Icons.explore_rounded,
                  label: l10n.featureExplore,
                  active: selected == 1,
                ),
                _animatedDestination(
                  outlined: Icons.emergency_outlined,
                  filled: Icons.emergency_rounded,
                  label: l10n.featureEmergency,
                  active: selected == 2,
                  activeColor: RihlaReferenceTokens.emergencyRed,
                ),
                _animatedDestination(
                  outlined: Icons.person_outline_rounded,
                  filled: Icons.person_rounded,
                  label: l10n.featureProfile,
                  active: selected == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A destination whose selected icon gently scales for a premium transition.
  NavigationDestination _animatedDestination({
    required IconData outlined,
    required IconData filled,
    required String label,
    required bool active,
    Color? activeColor,
  }) {
    final color = activeColor ?? RihlaReferenceTokens.mapTeal;
    return NavigationDestination(
      label: label,
      icon: Icon(outlined),
      selectedIcon: AnimatedScale(
        scale: active ? 1.12 : 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        child: Icon(filled, color: color),
      ),
    );
  }
}
