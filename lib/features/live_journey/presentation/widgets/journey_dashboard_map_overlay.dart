import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/live_journey/domain/entities/dashboard_display_mode.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/providers/live_journey_providers.dart';
import 'package:rihla/features/live_journey/presentation/widgets/journey_dashboard.dart';
import 'package:rihla/features/live_journey/presentation/widgets/journey_dashboard_floating.dart';

/// Map overlay that renders the live journey dashboard when a trip is active.
class JourneyDashboardMapOverlay extends ConsumerWidget {
  const JourneyDashboardMapOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveJourneyControllerProvider);
    if (state is! LiveJourneyActive) return const SizedBox.shrink();

    if (state.displayMode == DashboardDisplayMode.floating) {
      return JourneyDashboardFloating(
        state: state,
        onCollapse: () => ref
            .read(liveJourneyControllerProvider.notifier)
            .setDisplayMode(DashboardDisplayMode.collapsed),
        onExpand: () => ref
            .read(liveJourneyControllerProvider.notifier)
            .setDisplayMode(DashboardDisplayMode.expanded),
      );
    }

    return const JourneyDashboard();
  }
}
