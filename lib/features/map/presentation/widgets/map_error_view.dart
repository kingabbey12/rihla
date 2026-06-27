import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Full-bleed error state shown when the map engine fails to load.
class MapErrorView extends StatelessWidget {
  const MapErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 56,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.mapErrorTitle,
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.mapErrorMessage,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRetry,
                child: Text(context.l10n.mapRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
