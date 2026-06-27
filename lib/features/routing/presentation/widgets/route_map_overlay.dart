import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/live_journey/presentation/providers/live_journey_providers.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/routing/presentation/widgets/route_error_overlay.dart';
import 'package:rihla/features/routing/presentation/widgets/route_loading_overlay.dart';
import 'package:rihla/features/routing/presentation/widgets/route_selection_sheet.dart';

/// Map overlay for route loading, selection, and error states.
class RouteMapOverlay extends ConsumerWidget {
  const RouteMapOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeControllerProvider);

    ref.listen(routeControllerProvider, (previous, next) {
      if (next is RouteConfirmed) {
        ref.read(liveJourneyControllerProvider.notifier).start(next.selected);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.routeConfirmedMessage)),
        );
        ref.read(journeyControllerProvider.notifier).completeJourney();
        ref.read(routeControllerProvider.notifier).acknowledgeConfirmed();
      }
    });

    return switch (routeState) {
      RouteLoading() => const RouteLoadingOverlay(),
      RouteError() => RouteErrorOverlay(
          onRetry: () =>
              ref.read(routeControllerProvider.notifier).retry(),
          onCancel: () => _cancel(ref),
        ),
      RouteReady(:final result) => RouteSelectionSheet(
          result: result,
          selectedRouteId: null,
          onSelect: (id) =>
              ref.read(routeControllerProvider.notifier).selectRoute(id),
          onConfirm: () {},
          onCancel: () => _cancel(ref),
        ),
      RouteSelected(:final result, :final selected) => RouteSelectionSheet(
          result: result,
          selectedRouteId: selected.id,
          onSelect: (id) =>
              ref.read(routeControllerProvider.notifier).selectRoute(id),
          onConfirm: () =>
              ref.read(routeControllerProvider.notifier).confirmSelection(),
          onCancel: () => _cancel(ref),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  void _cancel(WidgetRef ref) {
    ref.read(liveJourneyControllerProvider.notifier).stop();
    ref.read(routeControllerProvider.notifier).clear();
    ref.read(journeyControllerProvider.notifier).cancel();
  }
}
