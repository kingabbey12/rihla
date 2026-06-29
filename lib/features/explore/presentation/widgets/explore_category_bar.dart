import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_state.dart';
import 'package:rihla/features/explore/presentation/extensions/explore_category_style.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';

/// Horizontal premium category pills shown while browsing a category.
class ExploreCategoryBar extends ConsumerWidget {
  const ExploreCategoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exploreControllerProvider);
    final selected = switch (state) {
      ExploreReady(:final category) => category,
      ExploreLoading(:final category) => category,
      ExplorePlaceSelected(:final previous) => previous.category,
      _ => null,
    };

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: ExploreCategory.values.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _DiscoverPill(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(exploreControllerProvider.notifier).showDiscovery();
              },
            );
          }
          final category = ExploreCategory.values[index - 1];
          final isSelected = selected == category;
          return _CategoryPill(
            category: category,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              ref
                  .read(exploreControllerProvider.notifier)
                  .selectCategory(category);
            },
          );
        },
      ),
    );
  }
}

class _DiscoverPill extends StatelessWidget {
  const _DiscoverPill({required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Discover',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final ExploreCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = category.gradient;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? gradient.last.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.12),
            blurRadius: isSelected ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  category.glyph,
                  size: 18,
                  color: isSelected ? Colors.white : category.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  category.shortLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
