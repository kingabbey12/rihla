import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Shown when the mock search service fails.
class SearchErrorView extends StatelessWidget {
  const SearchErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 52,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.searchErrorTitle,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.searchErrorMessage,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.l10n.searchRetry),
            ),
          ],
        ),
      ),
    );
  }
}
