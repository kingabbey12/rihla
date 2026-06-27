import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

class RouteLoadingOverlay extends StatelessWidget {
  const RouteLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: 16),
                Text(context.l10n.routeCalculating),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
