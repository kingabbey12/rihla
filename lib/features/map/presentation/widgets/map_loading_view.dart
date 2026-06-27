import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Full-bleed loading state shown while the map style initializes.
class MapLoadingView extends StatelessWidget {
  const MapLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.mapLoading,
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
