import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_selectors.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:rihla/routes/route_paths.dart';

/// Idle "AI Home Dashboard" content shown on the full-screen map: quick saved
/// place shortcuts and the AI journey advisor prompt. Hidden as soon as the user
/// starts planning, exploring, navigating, or enters emergency mode.
class HomeDashboardOverlay extends ConsumerWidget {
  const HomeDashboardOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNavigating = ref.watch(navigationIsActiveProvider);
    final journey = ref.watch(journeyControllerProvider);
    final exploreActive = ref.watch(exploreActiveProvider);
    final emergencyActive = ref.watch(emergencyActiveProvider);

    final isHome = !isNavigating &&
        journey is JourneyIdle &&
        !exploreActive &&
        !emergencyActive;

    final mediaQuery = MediaQuery.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: !isHome
          ? const SizedBox.shrink()
          : Stack(
              key: const ValueKey('home_dashboard'),
              children: [
                Positioned(
                  top: mediaQuery.padding.top + 76,
                  left: 16,
                  right: 16,
                  child: const _HomeShortcutsRow(),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 96 + mediaQuery.padding.bottom,
                  child: const _AiJourneyPromptCard(),
                ),
              ],
            ),
    );
  }
}

class _HomeShortcutsRow extends ConsumerWidget {
  const _HomeShortcutsRow();

  void _select(WidgetRef ref, SearchPlace place) {
    ref.read(searchSelectionProvider).select(place);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(searchHomeProvider).value;
    final work = ref.watch(searchWorkProvider).value;
    final favorites = ref.watch(searchFavoritesProvider).value ?? const [];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _ShortcutPill(
            icon: Icons.home_rounded,
            label: home?.name ?? context.l10n.searchAddHome,
            highlighted: home != null,
            onTap: home != null
                ? () => _select(ref, home)
                : () => context.push(RoutePaths.search),
          ),
          const SizedBox(width: 10),
          _ShortcutPill(
            icon: Icons.work_rounded,
            label: work?.name ?? context.l10n.searchAddWork,
            highlighted: work != null,
            onTap: work != null
                ? () => _select(ref, work)
                : () => context.push(RoutePaths.search),
          ),
          for (final fav in favorites) ...[
            const SizedBox(width: 10),
            _ShortcutPill(
              icon: Icons.favorite_rounded,
              label: fav.name,
              highlighted: true,
              onTap: () => _select(ref, fav),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShortcutPill extends StatelessWidget {
  const _ShortcutPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(22),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: highlighted ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AI journey recommendation card (idle prompt state). When the AI advisor has
/// produced a plan it is surfaced through the journey flow; on the idle home it
/// invites the user to start, routing into search.
class _AiJourneyPromptCard extends StatelessWidget {
  const _AiJourneyPromptCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        onTap: () => context.push(RoutePaths.search),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.aiJourneyAdvisorTitle,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.searchWhereTo,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
