import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/app/coordinators/driving_session_coordinator.dart';
import 'package:rihla/core/observability/breadcrumb.dart';
import 'package:rihla/core/observability/observability_providers.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
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
      final wasSheet = previous is RouteReady || previous is RouteSelected;
      final isSheet = next is RouteReady || next is RouteSelected;
      if (!wasSheet && isSheet) {
        ref.read(appLoggerProvider).log(
              'preview_sheet_shown',
              category: ObservabilityCategory.navigation,
            );
      }
    });

    return switch (routeState) {
      RouteLoading() => const RouteLoadingOverlay(),
      RouteError(:final failure) => RouteErrorOverlay(
          failure: failure,
          onRetry: () =>
              ref.read(routeControllerProvider.notifier).retry(),
          onCancel: () => _cancel(ref),
        ),
      RouteReady(:final result) => _selectionSheet(
          ref: ref,
          result: result,
          selectedRouteId:
              result.primaryRouteId ?? result.routes.firstOrNull?.id,
        ),
      RouteSelected(:final result, :final selected) => _selectionSheet(
          ref: ref,
          result: result,
          selectedRouteId: selected.id,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _selectionSheet({
    required WidgetRef ref,
    required RouteResult result,
    required String? selectedRouteId,
  }) {
    final destinationName = switch (ref.watch(journeyControllerProvider)) {
      JourneyPreview(:final summary) => summary.destination.name,
      _ => null,
    };

    return RouteSelectionSheet(
      result: result,
      destinationName: destinationName,
      selectedRouteId: selectedRouteId,
      onSelect: (id) =>
          ref.read(routeControllerProvider.notifier).selectRoute(id),
      onConfirm: () => _confirm(ref, selectedRouteId),
      onCancel: () => _cancel(ref),
    );
  }

  void _confirm(WidgetRef ref, String? selectedRouteId) {
    final notifier = ref.read(routeControllerProvider.notifier);
    final current = ref.read(routeControllerProvider);
    if (current is! RouteSelected && selectedRouteId != null) {
      notifier.selectRoute(selectedRouteId);
    }
    notifier.confirmSelection();
  }

  void _cancel(WidgetRef ref) {
    ref.read(drivingSessionCoordinatorProvider).cancelDrivingSession();
  }
}
