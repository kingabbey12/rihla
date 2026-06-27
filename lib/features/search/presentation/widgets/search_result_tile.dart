import 'package:flutter/material.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

/// A single search result or recent/saved place row.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    required this.place,
    required this.onTap,
    this.trailing,
    this.leadingIcon,
    super.key,
  });

  final SearchPlace place;
  final VoidCallback onTap;
  final Widget? trailing;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  leadingIcon ?? _iconForCategory(place.category),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForCategory(String? category) => switch (category) {
        'airport' => Icons.flight,
        'mall' => Icons.shopping_bag_outlined,
        'university' => Icons.school_outlined,
        'park' => Icons.park_outlined,
        'museum' => Icons.museum_outlined,
        'mosque' => Icons.mosque_outlined,
        'stadium' => Icons.stadium_outlined,
        'entertainment' => Icons.celebration_outlined,
        'district' => Icons.location_city_outlined,
        _ => Icons.place_outlined,
      };
}
