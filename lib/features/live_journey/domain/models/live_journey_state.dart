import 'package:rihla/features/live_journey/domain/entities/dashboard_display_mode.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_metrics.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Lifecycle state of the live journey dashboard.
sealed class LiveJourneyState {
  const LiveJourneyState();
}

/// No active live journey.
final class LiveJourneyInactive extends LiveJourneyState {
  const LiveJourneyInactive();
}

/// An active trip with live metric updates.
final class LiveJourneyActive extends LiveJourneyState {
  const LiveJourneyActive({
    required this.route,
    required this.metrics,
    required this.displayMode,
    required this.startedAt,
    this.progressPercent = 0,
  });

  final RouteSummary route;
  final LiveJourneyMetrics metrics;
  final DashboardDisplayMode displayMode;
  final DateTime startedAt;

  /// Trip progress 0–100 based on remaining distance.
  final double progressPercent;

  LiveJourneyActive copyWith({
    RouteSummary? route,
    LiveJourneyMetrics? metrics,
    DashboardDisplayMode? displayMode,
    DateTime? startedAt,
    double? progressPercent,
  }) {
    return LiveJourneyActive(
      route: route ?? this.route,
      metrics: metrics ?? this.metrics,
      displayMode: displayMode ?? this.displayMode,
      startedAt: startedAt ?? this.startedAt,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }
}
