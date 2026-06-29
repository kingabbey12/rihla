import 'package:flutter/material.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/presentation/extensions/explore_category_style.dart';

/// Friendly empty state shown when a category has no nearby results.
class ExploreEmptyState extends StatelessWidget {
  const ExploreEmptyState({
    required this.category,
    required this.onDiscover,
    required this.onWiden,
    super.key,
  });

  final ExploreCategory? category;
  final VoidCallback onDiscover;
  final VoidCallback onWiden;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = category?.gradient ??
        const [Color(0xFF14A3A3), Color(0xFF0D6E6E)];
    final label = category?.shortLabel.toLowerCase() ?? 'places';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient
                            .map((c) => c.withValues(alpha: 0.16))
                            .toList(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category?.glyph ?? Icons.travel_explore_rounded,
                      size: 46,
                      color: gradient.last,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No $label nearby',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "We couldn't find anything here yet. Try widening your "
                  'search area, or discover another category.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onWiden,
                        icon: const Icon(Icons.travel_explore, size: 18),
                        label: const Text('Widen area'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onDiscover,
                        icon: const Icon(Icons.grid_view_rounded, size: 18),
                        label: const Text('Discover'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
