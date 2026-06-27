import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_state.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';

/// Horizontal category chips for Explore discovery.
class ExploreCategoryBar extends ConsumerWidget {
  const ExploreCategoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(exploreControllerProvider);
    final selected = switch (state) {
      ExploreReady(:final category) => category,
      ExploreLoading(:final category) => category,
      ExplorePlaceSelected(:final previous) => previous.category,
      _ => null,
    };

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: ExploreCategory.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = ExploreCategory.values[index];
            final isSelected = selected == category;
            return FilterChip(
              label: Text(
                category.displayName,
                style: theme.textTheme.labelMedium,
              ),
              selected: isSelected,
              onSelected: (_) => ref
                  .read(exploreControllerProvider.notifier)
                  .selectCategory(category),
            );
          },
        ),
      ),
    );
  }
}
