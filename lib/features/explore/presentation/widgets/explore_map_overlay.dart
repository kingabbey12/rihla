import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/explore/domain/entities/explore_state.dart';
import 'package:rihla/features/explore/domain/repositories/explore_repository.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_category_bar.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_filters_sheet.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_place_sheet.dart';

/// Map overlay for the Explore discovery platform.
class ExploreMapOverlay extends ConsumerWidget {
  const ExploreMapOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(exploreActiveProvider);
    if (!active) return const SizedBox.shrink();

    final state = ref.watch(exploreControllerProvider);
    final recommendations = ref.watch(exploreJourneyRecommendationsProvider);
    final topPadding = MediaQuery.paddingOf(context).top + 120;

    return Stack(
      children: [
        Positioned(
          top: topPadding,
          left: 12,
          right: 12,
          child: const ExploreCategoryBar(),
        ),
        Positioned(
          top: topPadding + 56,
          right: 12,
          child: IconButton.filled(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const ExploreFiltersSheet(),
            ),
            icon: const Icon(Icons.tune),
          ),
        ),
        if (recommendations case AsyncData(:final value) when value.isNotEmpty)
          Positioned(
            left: 12,
            right: 12,
            bottom: 120 + MediaQuery.paddingOf(context).bottom,
            child: _JourneyRecommendationsBanner(recommendations: value),
          ),
        if (state is ExploreLoading)
          const Center(child: CircularProgressIndicator()),
        if (state is ExplorePlaceSelected)
          ExplorePlaceSheet(
            place: state.place,
            onDismiss: () =>
                ref.read(exploreControllerProvider.notifier).dismissPlace(),
          ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 8,
          child: IconButton.filledTonal(
            onPressed: () =>
                ref.read(exploreControllerProvider.notifier).deactivate(),
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}

class _JourneyRecommendationsBanner extends StatelessWidget {
  const _JourneyRecommendationsBanner({required this.recommendations});

  final List<ExploreJourneyRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = recommendations.first;
    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Journey suggestion',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(top.reason, style: theme.textTheme.bodyMedium),
            if (top.places.isNotEmpty)
              Text(
                top.places.first.name,
                style: theme.textTheme.titleSmall,
              ),
          ],
        ),
      ),
    );
  }
}
