import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/safety/presentation/providers/safety_providers.dart';
import 'package:rihla/features/safety/presentation/widgets/safety_dashboard.dart';

/// Map overlay for journey risk card and expandable safety dashboard.
class SafetyMapOverlay extends ConsumerStatefulWidget {
  const SafetyMapOverlay({super.key});

  @override
  ConsumerState<SafetyMapOverlay> createState() => _SafetyMapOverlayState();
}

class _SafetyMapOverlayState extends ConsumerState<SafetyMapOverlay> {
  bool _dashboardOpen = false;

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(navigationSessionControllerProvider);
    if (navState is! NavigationSessionActive) return const SizedBox.shrink();

    final assessment = ref.watch(safetyAssessmentProvider);
    final hazards = ref.watch(safetyHazardsProvider);
    if (assessment == null) return const SizedBox.shrink();

    if (_dashboardOpen) {
      return SafetyDashboard(
        assessment: assessment,
        hazards: hazards,
        onClose: () => setState(() => _dashboardOpen = false),
      );
    }

    final bottom = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 100 + bottom,
      child: JourneyRiskCard(
        assessment: assessment,
        onOpenDashboard: () => setState(() => _dashboardOpen = true),
      ),
    );
  }
}
