import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/explore/domain/entities/explore_state.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_category_bar.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_empty_state.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_filters_sheet.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_landing_overlay.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_place_sheet.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_recommendation_card.dart';

/// Map overlay for the Explore discovery platform.
class ExploreMapOverlay extends ConsumerWidget {
  const ExploreMapOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(exploreActiveProvider);
    if (!active) return const SizedBox.shrink();

    final state = ref.watch(exploreControllerProvider);
    final topPadding = MediaQuery.paddingOf(context).top;

    final selectedCategory = switch (state) {
      ExploreReady(:final category) => category,
      ExploreLoading(:final category) => category,
      ExplorePlaceSelected(:final previous) => previous.category,
      _ => null,
    };
    final isPlaceSelected = state is ExplorePlaceSelected;
    final showLanding = !isPlaceSelected && selectedCategory == null;

    return Stack(
      children: [
        if (showLanding)
          const ExploreLandingOverlay()
        else ...[
          Positioned(
            top: topPadding + 120,
            left: 12,
            right: 12,
            child: Row(
              children: [
                const Expanded(child: ExploreCategoryBar()),
                const SizedBox(width: 8),
                _FilterButton(
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const ExploreFiltersSheet(),
                  ),
                ),
              ],
            ),
          ),
          if (!isPlaceSelected) const _RecommendationsStrip(),
        ],
        if (state is ExploreLoading)
          const Center(child: CircularProgressIndicator()),
        if (state is ExploreReady &&
            state.places.isEmpty &&
            state.category != null)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ExploreEmptyState(
                category: state.category,
                onDiscover: () =>
                    ref.read(exploreControllerProvider.notifier).showDiscovery(),
                onWiden: () => ref
                    .read(exploreControllerProvider.notifier)
                    .applyFilter(
                      state.filter.copyWith(maxDistanceKm: 100),
                    ),
              ),
            ),
          ),
        if (state is ExplorePlaceSelected)
          ExplorePlaceSheet(
            place: state.place,
            onDismiss: () =>
                ref.read(exploreControllerProvider.notifier).dismissPlace(),
          ),
        Positioned(
          top: topPadding + 8,
          left: 8,
          child: IconButton.filledTonal(
            onPressed: () =>
                ref.read(exploreControllerProvider.notifier).deactivate(),
            icon: const Icon(Icons.close),
            tooltip: 'Close Explore',
          ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}

/// Horizontal AI recommendation strip shown above the bottom navigation while
/// browsing a category.
class _RecommendationsStrip extends ConsumerWidget {
  const _RecommendationsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(exploreJourneyRecommendationsProvider);
    if (recommendations case AsyncData(:final value) when value.isNotEmpty) {
      final bottom = MediaQuery.paddingOf(context).bottom;
      return Positioned(
        left: 0,
        right: 0,
        bottom: 104 + bottom,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: value.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => ExploreRecommendationCard(
                recommendation: value[index],
                onTap: (place) => ref
                    .read(exploreControllerProvider.notifier)
                    .selectPlace(place),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
