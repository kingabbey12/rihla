import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_card_sheet.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_error_overlay.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_loading_overlay.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';

/// Map overlay that renders journey loading, error, and preview states.
class JourneyMapOverlay extends ConsumerWidget {
  const JourneyMapOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyState = ref.watch(journeyControllerProvider);
    final routeState = ref.watch(routeControllerProvider);

    // Once routing has taken over (loading/ready/selected/confirmed) the
    // RouteMapOverlay owns the bottom sheet — don't also show the journey card.
    final routingActive = routeState is! RouteIdle;

    return switch (journeyState) {
      JourneyLoading() => const JourneyLoadingOverlay(),
      JourneyError(:final failure) => JourneyErrorOverlay(
          failure: failure,
          onRetry: () =>
              ref.read(journeyControllerProvider.notifier).retry(),
          onCancel: () =>
              ref.read(journeyControllerProvider.notifier).cancel(),
        ),
      JourneyPreview(:final summary) when !routingActive => JourneyCardSheet(
          summary: summary,
          onStart: () async {
            await ref.read(journeyControllerProvider.notifier).startJourney();
          },
          onCancel: () =>
              ref.read(journeyControllerProvider.notifier).cancel(),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
