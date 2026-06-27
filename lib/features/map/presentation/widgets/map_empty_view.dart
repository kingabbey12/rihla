import 'package:flutter/material.dart';
import 'package:rihla/core/constants/app_constants.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Dismissible card shown when a location fix can't be resolved.
/// Floats above the map so the map stays usable behind it.
class MapEmptyView extends StatelessWidget {
  const MapEmptyView({
    required this.onRetry,
    required this.onDismiss,
    super.key,
  });

  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 40,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.mapLocationUnavailableTitle,
              textAlign: TextAlign.center,
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.mapLocationUnavailableMessage,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onDismiss,
                  child: Text(context.l10n.mapDismiss),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.mapRetry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
