import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Overlay shown when journey planning fails.
class JourneyErrorOverlay extends StatelessWidget {
  const JourneyErrorOverlay({
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.route_outlined,
                  size: 48,
                  color: context.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.journeyErrorTitle,
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.journeyErrorMessage,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.journeyRetry),
                ),
                TextButton(
                  onPressed: onCancel,
                  child: Text(context.l10n.journeyCancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
