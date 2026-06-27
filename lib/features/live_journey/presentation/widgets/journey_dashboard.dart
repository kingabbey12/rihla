import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/live_journey/domain/entities/dashboard_display_mode.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/providers/live_journey_providers.dart';
import 'package:rihla/features/live_journey/presentation/widgets/journey_dashboard_collapsed.dart';
import 'package:rihla/features/live_journey/presentation/widgets/journey_dashboard_expanded.dart';

/// Persistent in-journey dashboard with collapsed and expanded modes.
class JourneyDashboard extends ConsumerWidget {
  const JourneyDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveJourneyControllerProvider);
    if (state is! LiveJourneyActive) return const SizedBox.shrink();

    return switch (state.displayMode) {
      DashboardDisplayMode.collapsed => JourneyDashboardCollapsed(
          state: state,
          onExpand: () => ref
              .read(liveJourneyControllerProvider.notifier)
              .setDisplayMode(DashboardDisplayMode.expanded),
          onFloat: () => ref
              .read(liveJourneyControllerProvider.notifier)
              .setDisplayMode(DashboardDisplayMode.floating),
        ),
      DashboardDisplayMode.expanded => JourneyDashboardExpanded(
          state: state,
          onCollapse: () => ref
              .read(liveJourneyControllerProvider.notifier)
              .setDisplayMode(DashboardDisplayMode.collapsed),
          onFloat: () => ref
              .read(liveJourneyControllerProvider.notifier)
              .setDisplayMode(DashboardDisplayMode.floating),
        ),
      DashboardDisplayMode.floating => const SizedBox.shrink(),
    };
  }
}
