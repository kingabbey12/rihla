import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Shown when a query returns no mock matches.
class SearchEmptyView extends StatelessWidget {
  const SearchEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 52,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.searchEmptyTitle,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.searchEmptyMessage,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
