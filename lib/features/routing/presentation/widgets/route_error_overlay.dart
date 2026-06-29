import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/routing/domain/errors/route_failure.dart';

/// Overlay shown when route calculation fails.
///
/// Surfaces the specific [RouteFailure] reason (network, server, empty, parse)
/// rather than a single generic message.
class RouteErrorOverlay extends StatelessWidget {
  const RouteErrorOverlay({
    required this.onRetry,
    required this.onCancel,
    this.failure,
    super.key,
  });

  final RouteFailure? failure;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final f = failure;
    final title = switch (f) {
      RouteNetworkFailure() => 'Network error',
      RouteServerFailure() => 'Routing service unavailable',
      RouteEmptyFailure() => 'No route found',
      RouteParseFailure() => 'Routing service unavailable',
      _ => context.l10n.routeErrorTitle,
    };
    final message = f?.message ?? context.l10n.routeErrorMessage;

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
                  _iconFor(f),
                  size: 48,
                  color: context.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (kDebugMode && f != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    f.runtimeType.toString(),
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.error,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.routeRetry),
                ),
                TextButton(
                  onPressed: onCancel,
                  child: Text(context.l10n.routeCancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(RouteFailure? failure) => switch (failure) {
        RouteNetworkFailure() => Icons.wifi_off,
        RouteServerFailure() || RouteParseFailure() => Icons.cloud_off,
        RouteEmptyFailure() => Icons.wrong_location_outlined,
        _ => Icons.alt_route,
      };
}
