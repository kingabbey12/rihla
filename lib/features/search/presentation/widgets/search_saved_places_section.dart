import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/presentation/widgets/search_section_header.dart';

/// Home, Work, and Favorites shortcuts.
class SearchSavedPlacesSection extends StatelessWidget {
  const SearchSavedPlacesSection({
    required this.home,
    required this.work,
    required this.favorites,
    required this.onPlaceTap,
    required this.onAddHome,
    required this.onAddWork,
    super.key,
  });

  final SearchPlace? home;
  final SearchPlace? work;
  final List<SearchPlace> favorites;
  final ValueChanged<SearchPlace> onPlaceTap;
  final VoidCallback onAddHome;
  final VoidCallback onAddWork;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchSectionHeader(title: context.l10n.searchSavedTitle),
        Row(
          children: [
            Expanded(
              child: _ShortcutCard(
                icon: Icons.home_outlined,
                label: home?.name ?? context.l10n.searchAddHome,
                subtitle: home?.address,
                onTap: home != null ? () => onPlaceTap(home!) : onAddHome,
                isPlaceholder: home == null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ShortcutCard(
                icon: Icons.work_outline,
                label: work?.name ?? context.l10n.searchAddWork,
                subtitle: work?.address,
                onTap: work != null ? () => onPlaceTap(work!) : onAddWork,
                isPlaceholder: work == null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SearchSectionHeader(title: context.l10n.searchFavorites),
        if (favorites.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              context.l10n.searchNoFavorites,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: favorites
                .map(
                  (place) => ActionChip(
                    avatar: const Icon(Icons.favorite, size: 16),
                    label: Text(place.name),
                    onPressed: () => onPlaceTap(place),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isPlaceholder
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
