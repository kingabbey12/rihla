import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_driving_copilot_panel.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_journey_review_sheet.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';

/// Orchestrates all three AI experiences on the map.
class AiCopilotMapOverlay extends ConsumerStatefulWidget {
  const AiCopilotMapOverlay({super.key});

  @override
  ConsumerState<AiCopilotMapOverlay> createState() =>
      _AiCopilotMapOverlayState();
}

class _AiCopilotMapOverlayState extends ConsumerState<AiCopilotMapOverlay> {
  bool _copilotExpanded = false;
  String? _lastAdvisorKey;
  DateTime? _lastSessionTick;

  @override
  Widget build(BuildContext context) {
    _watchJourneyAdvisor();
    _watchDrivingCopilot();
    _watchJourneyReview();

    final navState = ref.watch(navigationSessionControllerProvider);
    if (navState is NavigationSessionActive && navState.session.hasArrived) {
      return Stack(
        children: [
          Positioned.fill(
            child: AiJourneyReviewSheet(onDismiss: _dismissReview),
          ),
        ],
      );
    }

    if (navState is NavigationSessionActive) {
      return AiDrivingCopilotPanel(
        expanded: _copilotExpanded,
        onToggle: () => setState(() => _copilotExpanded = !_copilotExpanded),
      );
    }

    return const SizedBox.shrink();
  }

  void _watchJourneyAdvisor() {
    final journeyState = ref.watch(journeyControllerProvider);
    final routeState = ref.watch(routeControllerProvider);

    final summary = switch (journeyState) {
      JourneyPreview(:final summary) => summary,
      _ => null,
    };
    if (summary == null) return;

    final routeId = switch (routeState) {
      RouteSelected(:final selected) => selected.id,
      RouteReady(:final result) => result.primary?.id ?? 'preview',
      _ => 'preview',
    };

    final key = '${summary.destination.id}_$routeId';
    if (_lastAdvisorKey == key) return;
    _lastAdvisorKey = key;

    Future.microtask(() {
      ref.read(aiControllerProvider.notifier).loadJourneyAdvisor(summary);
    });
  }

  void _watchDrivingCopilot() {
    final navState = ref.watch(navigationSessionControllerProvider);
    if (navState is! NavigationSessionActive) {
      _lastSessionTick = null;
      return;
    }
    if (navState.session.hasArrived) return;

    final tick = navState.session.lastUpdatedAt;
    if (_lastSessionTick == tick) return;
    _lastSessionTick = tick;

    Future.microtask(() {
      ref
          .read(aiControllerProvider.notifier)
          .refreshDrivingCopilot(navState.session);
    });
  }

  void _watchJourneyReview() {
    final navState = ref.watch(navigationSessionControllerProvider);
    if (navState is! NavigationSessionActive) return;
    if (!navState.session.hasArrived) return;

    Future.microtask(() {
      ref
          .read(aiControllerProvider.notifier)
          .loadJourneyReview(navState.session);
    });
  }

  void _dismissReview() {
    ref.read(aiControllerProvider.notifier).dismissReview();
    ref.read(navigationSessionControllerProvider.notifier).stopSession();
    setState(() => _copilotExpanded = false);
  }
}
