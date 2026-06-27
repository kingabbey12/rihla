import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/app/coordinators/driving_session_coordinator.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_driving_copilot_panel.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_journey_review_sheet.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';

/// Pure UI overlay for AI copilot experiences during navigation.
class AiCopilotMapOverlay extends ConsumerStatefulWidget {
  const AiCopilotMapOverlay({super.key});

  @override
  ConsumerState<AiCopilotMapOverlay> createState() =>
      _AiCopilotMapOverlayState();
}

class _AiCopilotMapOverlayState extends ConsumerState<AiCopilotMapOverlay> {
  bool _copilotExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasArrived = ref.watch(navigationHasArrivedProvider);
    final isNavigating = ref.watch(navigationIsActiveProvider);

    if (hasArrived) {
      return Stack(
        children: [
          Positioned.fill(
            child: AiJourneyReviewSheet(onDismiss: _dismissReview),
          ),
        ],
      );
    }

    if (isNavigating) {
      return AiDrivingCopilotPanel(
        expanded: _copilotExpanded,
        onToggle: () => setState(() => _copilotExpanded = !_copilotExpanded),
      );
    }

    return const SizedBox.shrink();
  }

  void _dismissReview() {
    ref.read(drivingSessionCoordinatorProvider).completeJourneyReview();
    setState(() => _copilotExpanded = false);
  }
}
