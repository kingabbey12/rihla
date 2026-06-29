import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/journey/domain/errors/journey_failure.dart';

/// Overlay shown when journey planning fails.
///
/// Renders the *specific* failure (title + message) so the user always sees the
/// real cause — "Waiting for current location…", "No GPS signal", "Routing
/// service unavailable", "No route found", "Network error" — rather than a
/// single generic "Journey unavailable" dialog. Technical detail is shown only
/// in debug builds.
class JourneyErrorOverlay extends StatelessWidget {
  const JourneyErrorOverlay({
    required this.failure,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  final JourneyFailure failure;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  bool get _isWaiting => failure is JourneyLocationWaitingFailure;

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
                if (_isWaiting)
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                else
                  Icon(
                    _iconFor(failure),
                    size: 48,
                    color: context.colorScheme.error,
                  ),
                const SizedBox(height: 16),
                Text(
                  failure.title,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  failure.message,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (kDebugMode && failure.debugDetail != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    failure.debugDetail!,
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

  IconData _iconFor(JourneyFailure failure) => switch (failure) {
        JourneyGpsUnavailableFailure() ||
        JourneyOriginUnavailableFailure() =>
          Icons.gps_off,
        JourneyNetworkFailure() => Icons.wifi_off,
        JourneyRoutingUnavailableFailure() => Icons.cloud_off,
        JourneyNoRouteFailure() => Icons.wrong_location_outlined,
        JourneyInvalidCoordinatesFailure() => Icons.location_disabled,
        _ => Icons.route_outlined,
      };
}
